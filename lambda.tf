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
##  ./lambda.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------
locals {
  ecs_update_enabled      = try(length(var.ecs_cluster_arn), 0) > 0
  adhoc_ssm_enabled       = try(length(var.ssm_adhoc_command), 0) > 0
  named_ssm_enabled       = try(length(var.ssm_named_document), 0) > 0
  acm_certificate_enabled = try(length(var.acm_certificate_arn), 0) > 0
}


# ------------------------------------------------------------------------------
# SSL Update Lambda
# ------------------------------------------------------------------------------
module "lambda" {
  source  = "SevenPicoForks/lambda-function/aws"
  version = "2.0.1"
  context = module.context.self

  architectures                       = null
  cloudwatch_event_rules              = {}
  cloudwatch_lambda_insights_enabled  = false
  cloudwatch_logs_kms_key_arn         = null
  cloudwatch_logs_retention_in_days   = var.cloudwatch_log_retention_days
  cloudwatch_log_subscription_filters = {}
  description                         = "Update ACM, ECS, and EC2 with SSl certificate from secret."
  event_source_mappings               = {}
  filename                            = try(data.archive_file.lambda[0].output_path, "")
  function_name                       = module.context.id
  handler                             = "main.lambda_handler"
  ignore_external_function_updates    = false
  image_config                        = {}
  image_uri                           = null
  kms_key_arn                         = ""
  lambda_at_edge                      = false
  layers                              = []
  memory_size                         = 128
  package_type                        = "Zip"
  publish                             = false
  reserved_concurrent_executions      = -1
  role_name                           = "${module.context.id}-role"
  runtime                             = "python3.9"
  s3_bucket                           = null
  s3_key                              = null
  s3_object_version                   = null
  sns_subscriptions                   = {}
  source_code_hash                    = try(data.archive_file.lambda[0].output_base64sha256, "")
  ssm_parameter_names                 = null
  timeout                             = 10
  tracing_config_mode                 = null
  vpc_config                          = null

  lambda_environment = {
    variables = merge(
      try(length(var.acm_certificate_arn), 0) > 0 ? {
        SECRET_ARN : var.secret_arn
        ACM_CERTIFICATE_ARN : var.acm_certificate_arn
        KEYNAME_CERTIFICATE : var.keyname_certificate
        KEYNAME_PRIVATE_KEY : var.keyname_private_key
        KEYNAME_CERTIFICATE_CHAIN : var.keyname_certificate_chain
      } : {},
      try(length(var.acm_certificate_arn_replicas), 0) > 0 ? {
        ACM_CERTIFICATE_ARN_REPLICAS : var.acm_certificate_arn_replicas
      } : {},
      try(length(var.ssm_adhoc_command), 0) > 0 ? {
        SSM_SSL_UPDATE_COMMAND : var.ssm_adhoc_command
        SSM_TARGET_KEY : var.ssm_target_key
        SSM_TARGET_VALUES : join(",", var.ssm_target_values)
      } : {},
      try(length(var.ssm_named_document), 0) > 0 ? {
        SSM_SSL_NAMED_DOCUMENT : var.ssm_named_document
        SSM_TARGET_KEY : var.ssm_target_key
        SSM_TARGET_VALUES : join(",", var.ssm_target_values)
      } : {},
      try(length(var.ecs_cluster_arn), 0) > 0 ? {
        ECS_CLUSTER_ARN : var.ecs_cluster_arn
        ECS_SERVICE_ARNS : join(",", var.ecs_service_arns)
      } : {},
    )
  }
}

data "archive_file" "lambda" {
  count       = module.context.enabled ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/.build/lambda.zip"
}


# ------------------------------------------------------------------------------
# Lambda SNS Subscription
# ------------------------------------------------------------------------------
resource "aws_sns_topic_subscription" "lambda" {
  count     = module.context.enabled ? 1 : 0
  endpoint  = module.lambda.arn
  protocol  = "lambda"
  topic_arn = var.sns_topic_arn
}

resource "aws_lambda_permission" "sns" {
  count         = module.context.enabled ? 1 : 0
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_arn
  statement_id  = "AllowExecutionFromSNS"
}


# ------------------------------------------------------------------------------
# Lambda IAM
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda" {
  count      = module.context.enabled ? 1 : 0
  depends_on = [module.lambda]

  role       = "${module.context.id}-role"
  policy_arn = module.lambda_policy.policy_arn
}

module "lambda_policy" {
  source  = "SevenPicoForks/iam-policy/aws"
  version = "2.0.0"
  context = module.context.self

  description                   = "SSL Update Lambda Access Policy"
  iam_override_policy_documents = null
  iam_policy_enabled            = true
  iam_policy_id                 = null
  iam_source_json_url           = null
  iam_source_policy_documents   = null

  iam_policy_statements = merge(
    local.acm_certificate_enabled ? {
      SecretRead = {
        effect = "Allow"
        actions = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
        ]
        resources = [var.secret_arn]
      }

      SecretDecrypt = {
        effect = "Allow"
        actions = [
          "kms:Decrypt",
          "kms:DescribeKey",
        ]
        resources = [var.kms_key_arn]
      }

      ACMImport = { #note acm_certificate_arn_replicas
        effect = "Allow"
        actions = [
          "acm:ImportCertificate"
        ]
        resources = concat([var.acm_certificate_arn], length(var.acm_certificate_arn_replicas) > 0 ? values(var.acm_certificate_arn_replicas) : [])
      }
    } : {},

    local.adhoc_ssm_enabled ? {
      SSMSendCommand = {
        effect = "Allow"
        actions = [
          "ssm:SendCommand",
        ]
        resources = ["*"] # FIXME - can this be limited?
      }
    } : {},

    local.ecs_update_enabled ? {
      ECSUpdateService = {
        effect = "Allow"
        actions = [
          "ecs:UpdateService"
        ]
        resources = [var.ecs_service_arns]
      }
    } : {},
    local.named_ssm_enabled ? {
      EC2SSLUpdate = {
        effect = "Allow"
        actions = [
          "ssm:SendCommand",
          "ssm:GetDocument",
        ]
        resources = ["*"]
      }
    } : {},
  )
}
