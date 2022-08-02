import os
import logging
from dataclasses import dataclass

def get_required_var(name):
    try:
        return os.environ[name]
    except KeyError:
        logging.critical(f"Environment variable {name} not set.")

def get_optional_var(name, default=None):
    try:
        return os.environ[name]
    except KeyError:
        logging.warn(f"Environment variable {name} not set. Using default: {default}")
        return default

@dataclass
class Config:
    secret_arn                = get_optional_var('SECRET_ARN')
    acm_certificate_arn       = get_optional_var('ACM_CERTIFICATE_ARN')
    keyname_certificate       = get_optional_var('KEYNAME_CERTIFICATE', 'CERTIFICATE')
    keyname_private_key       = get_optional_var('KEYNAME_PRIVATE_KEY', 'CERTIFICATE_PRIVATE_KEY')
    keyname_certificate_chain = get_optional_var('KEYNAME_CERTIFICATE_CHAIN', 'CERTIFICATE_CHAIN')

    ssm_ssl_update_command    = get_optional_var('SSM_SSL_UPDATE_COMMAND')
    ssm_target_key            = get_optional_var('SSM_TARGET_KEY')
    ssm_target_values         = get_optional_var('SSM_TARGET_VALUES', [])

    ecs_service_arns          = get_optional_var('ECS_SERVICE_ARNS', [])
    ecs_cluster_arn           = get_optional_var('ECS_SERVICE_ARNS')
