# ------------------------------------------------------------------------------
# SSL Update Lambda
# ------------------------------------------------------------------------------
module "lambda" {
  source  = "app.terraform.io/SevenPico/lambda-function/aws"
  version = "0.1.0.2"
  context = module.this.context

  architectures                       = null
  cloudwatch_event_rules              = {}
  cloudwatch_lambda_insights_enabled  = false
  cloudwatch_logs_kms_key_arn         = null
  cloudwatch_logs_retention_in_days   = var.cloudwatch_log_retention_days
  cloudwatch_log_subscription_filters = {}
  description                         = "Update ACM, ECS, and EC2 with SSl certificate from secret."
  event_source_mappings               = {}
  filename                            = one(data.archive_file.lambda[*].output_path)
  function_name                       = module.this.id
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
  role_name                           = "${module.this.id}-role"
  runtime                             = "python3.9"
  s3_bucket                           = null
  s3_key                              = null
  s3_object_version                   = null
  sns_subscriptions                   = {}
  source_code_hash                    = one(data.archive_file.lambda[*].output_base64sha256)
  ssm_parameter_names                 = null
  timeout                             = 3
  tracing_config_mode                 = null
  vpc_config                          = null

  lambda_environment = {
    variables = merge(
      var.acm_enabled ? {
        SECRET_ARN : var.secret_arn
        ACM_CERTIFICATE_ARN : var.acm_certificate_arn
        KEYNAME_CERTIFICATE : var.keyname_certificate
        KEYNAME_PRIVATE_KEY : var.keyname_private_key
        KEYNAME_CERTIFICATE_CHAIN : var.keyname_certificate_chain
      } : {},
      var.ssm_enabled ? {
        SSM_SSL_UPDATE_COMMAND : var.ssm_ssl_update_command
        SSM_TARGET_KEY : var.ssm_target_key
        SSM_TARGET_VALUES : join(",", var.ssm_target_values)
      } : {},
      var.ecs_enabled ? {
        ECS_CLUSTER_ARN : var.ecs_cluster_arn
        ECS_SERVICE_ARNS : join(",", var.ecs_service_arns)
      } : {},
    )
  }
}

data "archive_file" "lambda" {
  count       = module.this.enabled ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/.build/lambda.zip"
}


# ------------------------------------------------------------------------------
# Lambda SNS Subscription
# ------------------------------------------------------------------------------
resource "aws_sns_topic_subscription" "lambda" {
  endpoint  = module.lambda.arn
  protocol  = "lambda"
  topic_arn = var.sns_topic_arn
}

resource "aws_lambda_permission" "sns" {
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
  count      = module.this.enabled ? 1 : 0
  depends_on = [module.lambda]

  role       = "${module.this.id}-role"
  policy_arn = module.lambda_policy.policy_arn
}

module "lambda_policy" {
  source  = "cloudposse/iam-policy/aws"
  version = "0.4.0"
  context = module.this.context

  description                   = "SSL Update Lambda Access Policy"
  iam_override_policy_documents = null
  iam_policy_enabled            = true
  iam_policy_id                 = null
  iam_source_json_url           = null
  iam_source_policy_documents   = null

  iam_policy_statements = merge(
    var.acm_enabled ? {
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

      ACMImport = {
        effect = "Allow"
        actions = [
          "acm:ImportCertificate"
        ]
        resources = [var.acm_certificate_arn]
      }
    } : {},

    var.ssm_enabled ? {
      SSMSendCommand = {
        effect = "Allow"
        actions = [
          "ssm:SendCommand",
        ]
        resources = ["*"] # FIXME - can this be limited?
      }
    } : {},

    var.ecs_enabled ? {
      ECSUpdateService = {
        effect = "Allow"
        actions = [
          "ecs:UpdateService"
        ]
        resources = var.ecs_service_arns
      }
    } : {}
  )
}
