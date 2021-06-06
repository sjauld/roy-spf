module "roy" {
  source = "git@github.com:sjauld/roy-spf.git//infra?ref=v0.1.0"

  secrets_kms_key_alias = "parameter_store_key"

  phishing_domain = "example-security.com"

  postmark_dkim_hostname = "20210518221727pm._domainkey"
  postmark_dkim_key      = "k=rsa;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCQQsUXG1GI5nxKLj8fXhYYf5LJNFVHjCsEphS69I+09/jCGKyOam7ZFFn3ItRZgX5fl5EjekLpC75vZFcQggFRfli5pJ1v2+igDv833cGIOgHX9Zw6ol0ahf/bPqurSGWjyi+KdfcA2fCWFf2fmVUkp5ihLPBrk+arAl1JCsSoeQIDAQAB"

  path_to_sender_zip  = "${path.module}/lambdas/sender.zip"
  path_to_tracker_zip = "${path.module}/lambdas/tracker.zip"

  tracker_mail_to = "stu@example.com"

  tags = {
    Name    = "example-security.com RoySPF"
    Project = "RoySPF"
  }
}
