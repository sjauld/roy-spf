variable "secrets_kms_key_alias" {
  description = "If you want to use a custom KMS key you can feed it in here"
  default     = "aws/ssm"
}

variable "path_to_sender_zip" {
  description = "The location of a zip file containing the sender binary"
}

variable "path_to_tracker_zip" {
  description = "The location of a zip file containing the sender binary"
}

variable "phishing_domain" {
  description = "The domain from which you will originate the phishing simulation. You'll need to have a corresponding Route53 zone set up."
  type        = string
}

variable "postmark_dkim_hostname" {
  description = "Should be something like yyyymmddhhmmsspm._domainkey"
  type        = string
}

variable "postmark_dkim_key" {
  description = "Should be something like k=rsa;p=MIG......"
  type        = string
}

variable "tags" {
  type = map(string)
}

variable "tracker_mail_from" {
  description = "The email address your tracker reports come from"
  default     = "gotcha"
}

variable "tracker_mail_to" {
  description = "The address to send mail to (probably your address!)"
}

variable "tracker_redirect_url_error" {
  description = "We'll send HTTP requests that aren't geniune phishing wins here"
  default     = "https://lmddgtfy.net/?q=nothing%20to%20see%20here"
}

variable "tracker_redirect_url_match" {
  description = "We'll send HTTP requests that are geniune phishing wins here"
  default     = "https://lmddgtfy.net/?q=help!%20I%20just%20fell%20victim%20to%20a%20phishing%20attack"
}
