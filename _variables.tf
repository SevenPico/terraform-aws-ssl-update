# TODO - descriptions

variable "sns_topic_arn" {
  type = string
}

variable "cloudwatch_log_retention_days" {
  type = number
  default = 90
}


# ACM
variable "acm_enabled" {
  type = bool
  default = false
  description = "Re-import certificate to ACM on SNS notification."
}

variable "secret_arn" {
  type = string
  default = ""
  description = "Required if update_acm is true."
}

variable "kms_key_arn" {
  type = string
  default = ""
  description = "Required if update_acm is true."
}

variable "acm_certificate_arn" {
  type = string
  default = ""
  description = "Required if update_acm is true."
}

variable "keyname_certificate" {
  type = string
  default = ""
  description = "Required if update_acm is true."
}

variable "keyname_private_key" {
  type = string
  default = ""
  description = "Required if update_acm is true."
}

variable "keyname_certificate_chain" {
  type = string
  default = ""
  description = "Required if update_acm is true."
}


# SSM
variable "ssm_enabled" {
  type = bool
  default = false
  description = "Run ssm_ssl_update_command on selected instatnces on SNS notification."
}

variable "ssm_ssl_update_command" {
  type = string
  default = ""
}

variable "ssm_target_key" {
  type = string
  default = ""
}

variable "ssm_target_values" {
  type = list(string)
  default = []
}


# ECS
variable "ecs_enabled" {
  type = bool
  default = false
  description = "Force update on selected ECS services on SNS notification."
}

variable "ecs_cluster_arn" {
  type = string
  default = ""
}

variable "ecs_service_arns" {
  type = list(string)
  default = []
}
