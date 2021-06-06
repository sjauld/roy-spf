# Roy's Serverless Phishing Framework Terraform Module

This module should give you everything you need to run some phishing  
simulations against your organisation. Please consult the
[main README](../README.md) for more information

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| random | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| path\_to\_sender\_zip | The location of a zip file containing the sender binary | `any` | n/a | yes |
| path\_to\_tracker\_zip | The location of a zip file containing the sender binary | `any` | n/a | yes |
| phishing\_domain | The domain from which you will originate the phishing simulation. You'll need to have a corresponding Route53 zone set up. | `string` | n/a | yes |
| postmark\_dkim\_hostname | Should be something like yyyymmddhhmmsspm.\_domainkey | `string` | n/a | yes |
| postmark\_dkim\_key | Should be something like k=rsa;p=MIG...... | `string` | n/a | yes |
| tags | n/a | `map(string)` | n/a | yes |
| tracker\_mail\_to | The address to send mail to (probably your address!) | `any` | n/a | yes |
| secrets\_kms\_key\_alias | If you want to use a custom KMS key you can feed it in here | `string` | `"aws/ssm"` | no |
| tracker\_mail\_from | The email address your tracker reports come from | `string` | `"gotcha"` | no |

## Outputs

No output.

