variable "kms_key_arn" {
  type = string
}

variable "secret_arn" {
  type = string
}

variable "acm_certificate_arn" {
  type = string
}

variable "keyname_certificate" {
  type = string
}

variable "keyname_private_key" {
  type = string
}

variable "keyname_certificate_chain" {
  type = string
}

variable "cloudwatch_log_retention_days" {
  type = number
  default = 90
}
