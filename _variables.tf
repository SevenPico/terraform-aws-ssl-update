## ----------------------------------------------------------------------------
##  Copyright 2023 SevenPico, Inc.
##
##  Licensed under the Apache License, Version 2.0 (the "License");
##  you may not use this file except in compliance with the License.
##  You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
##  Unless required by applicable law or agreed to in writing, software
##  distributed under the License is distributed on an "AS IS" BASIS,
##  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##  See the License for the specific language governing permissions and
##  limitations under the License.
## ----------------------------------------------------------------------------

## ----------------------------------------------------------------------------
##  ./_variables.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

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
