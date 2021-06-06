/*
* # Roy's Serverless Phishing Framework Terraform Module
*
* This module should give you everything you need to run some phishing
* simulations against your organisation. Please consult the
* [main README](../README.md) for more information
*
* ## Generating docs
*
* `terraform-docs markdown . --sort-by-required > README.md`
*/

data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

# =========================
# DNS
# =========================
data "aws_route53_zone" "main" {
  name = var.phishing_domain
}

# Postmark uses this to collect bounces and ensure spf compliance
resource "aws_route53_record" "return_path" {
  zone_id = data.aws_route53_zone.main.zone_id

  name    = "pm-bounces"
  type    = "CNAME"
  ttl     = 24 * 60 * 60
  records = ["pm.mtasv.net"]
}

# Postmark uses this to sign mail
resource "aws_route53_record" "dkim" {
  zone_id = data.aws_route53_zone.main.zone_id

  name    = var.postmark_dkim_hostname
  type    = "TXT"
  ttl     = 24 * 60 * 60
  records = [var.postmark_dkim_key]
}

# Email providers check this record to detemine whether to deliver non-compliant
# email - this protects us against other spammers/phishers
resource "aws_route53_record" "dmarc" {
  zone_id = data.aws_route53_zone.main.zone_id

  name    = "_dmarc"
  type    = "TXT"
  ttl     = 24 * 60 * 60
  records = ["v=DMARC1;p=reject;pct=100;sp=none;aspf=r;"]
}

# =========================
# Mailing lambda
# =========================

resource "aws_lambda_function" "sender" {
  function_name = "RoySPFSender"
  role          = aws_iam_role.sender.arn

  filename = var.path_to_sender_zip

  runtime = "go1.x"
  handler = "sender"

  environment {
    variables = {
      CHAMBER_KMS_KEY_ALIAS = var.secrets_kms_key_alias
      TRACKER_BASE_URL      = "https://${var.phishing_domain}"
    }
  }

  tags = var.tags
}

resource "aws_iam_role" "sender" {
  name               = "RoySPFSender"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "sender" {
  role       = aws_iam_role.sender.name
  policy_arn = aws_iam_policy.sender.arn
}

resource "aws_iam_policy" "sender" {
  name   = "RoySPFSender"
  policy = data.aws_iam_policy_document.sender.json
}

# Get the underlying key so we can give permissions
data "aws_kms_alias" "secrets" {
  name = "alias/${var.secrets_kms_key_alias}"
}

data "aws_iam_policy_document" "sender" {
  statement {
    sid       = "KMSDecrypt"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_alias.secrets.target_key_arn]
  }

  statement {
    sid = "SSMDescribeParameters"

    actions = [
      "ssm:DescribeParameters",
    ]

    resources = ["*"]
  }

  statement {
    sid = "SSMGetParameters"

    actions = [
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]

    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/roy-spf-sender/*",
    ]
  }

  statement {
    sid = "Logging"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

# =============================
# Tracking lambda + API Gateway
# =============================

# We need a certificate for our API Gateway
resource "aws_acm_certificate" "main" {
  domain_name       = var.phishing_domain
  validation_method = "DNS"

  tags = var.tags
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id

  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]

  ttl = 300
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

resource "aws_api_gateway_rest_api" "tracker" {
  name        = "RoySPFTracker"
  description = "An API gateway to track clicks on Roy SPF emails"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_domain_name" "tracker" {
  domain_name              = var.phishing_domain
  regional_certificate_arn = aws_acm_certificate_validation.main.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_route53_record" "tracker" {
  zone_id = data.aws_route53_zone.main.zone_id

  name = ""
  type = "A"

  alias {
    name                   = aws_api_gateway_domain_name.tracker.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.tracker.regional_zone_id
    evaluate_target_health = true
  }
}

resource "aws_api_gateway_deployment" "tracker" {
  description = "RoySPF tracker deployment"
  stage_name  = "tracker"

  rest_api_id = aws_api_gateway_rest_api.tracker.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.tracker,
    aws_api_gateway_integration.root,
  ]
}

resource "aws_api_gateway_base_path_mapping" "tracker" {
  api_id      = aws_api_gateway_rest_api.tracker.id
  stage_name  = aws_api_gateway_deployment.tracker.stage_name
  domain_name = aws_api_gateway_domain_name.tracker.domain_name
}

resource "aws_api_gateway_resource" "tracker" {
  rest_api_id = aws_api_gateway_rest_api.tracker.id
  parent_id   = aws_api_gateway_rest_api.tracker.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_lambda_function" "tracker" {
  function_name = "RoySPFTracker"
  role          = aws_iam_role.tracker.arn

  filename = var.path_to_tracker_zip

  runtime = "go1.x"
  handler = "tracker"

  environment {
    variables = {
      CHAMBER_KMS_KEY_ALIAS = var.secrets_kms_key_alias
      MAIL_FROM             = "${var.tracker_mail_from}@${var.phishing_domain}"
      MAIL_TO               = var.tracker_mail_to
      REDIRECT_URL_ERROR    = var.tracker_redirect_url_error
      REDIRECT_URL_MATCH    = var.tracker_redirect_url_match
    }
  }

  tags = var.tags
}

# Permissions
resource "aws_lambda_permission" "gateway_invocation" {
  statement_id  = "APIGatewayInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tracker.function_name
  principal     = "apigateway.amazonaws.com"
  # source_arn    = "${aws_api_gateway_rest_api.tracker.execution_arn}/*/GET*"
  source_arn = "${aws_api_gateway_rest_api.tracker.execution_arn}/*"
}

resource "aws_lambda_alias" "tracker" {
  name        = "production"
  description = "An alias that points at the current production version of the lambda"

  function_name    = aws_lambda_function.tracker.arn
  function_version = "$LATEST"

  lifecycle {
    ignore_changes = [function_version]
  }
}

resource "aws_iam_role" "tracker" {
  name               = "RoySPFTracker"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "tracker" {
  role       = aws_iam_role.tracker.name
  policy_arn = aws_iam_policy.tracker.arn
}

resource "aws_iam_policy" "tracker" {
  name   = "RoySPFTracker"
  policy = data.aws_iam_policy_document.tracker.json
}

data "aws_iam_policy_document" "tracker" {
  statement {
    sid       = "KMSDecrypt"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_alias.secrets.target_key_arn]
  }

  statement {
    sid = "SSMDescribeParameters"

    actions = [
      "ssm:DescribeParameters",
    ]

    resources = ["*"]
  }

  statement {
    sid = "SSMGetParameters"

    actions = [
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]

    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/roy-spf-tracker/*",
    ]
  }

  statement {
    sid = "Logging"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

resource "aws_api_gateway_method" "tracker" {
  rest_api_id   = aws_api_gateway_rest_api.tracker.id
  resource_id   = aws_api_gateway_resource.tracker.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "tracker" {
  rest_api_id = aws_api_gateway_rest_api.tracker.id
  resource_id = aws_api_gateway_resource.tracker.id
  http_method = "GET"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.tracker.invoke_arn
}


resource "aws_api_gateway_method" "root" {
  rest_api_id   = aws_api_gateway_rest_api.tracker.id
  resource_id   = aws_api_gateway_rest_api.tracker.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root" {
  rest_api_id = aws_api_gateway_rest_api.tracker.id
  resource_id = aws_api_gateway_rest_api.tracker.root_resource_id
  http_method = "GET"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.tracker.invoke_arn
}

# Add the encryption/decryption secret
resource "random_uuid" "secret" {}

resource "aws_ssm_parameter" "encryption_secret" {
  name   = "/roy-spf-sender/encryption-secret"
  type   = "SecureString"
  key_id = data.aws_kms_alias.secrets.target_key_arn
  value  = resource.random_uuid.secret.id
}

resource "aws_ssm_parameter" "decryption_secret" {
  name   = "/roy-spf-tracker/decryption-secret"
  type   = "SecureString"
  key_id = data.aws_kms_alias.secrets.target_key_arn
  value  = resource.random_uuid.secret.id
}
