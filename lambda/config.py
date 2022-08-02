import os
import logging
from dataclasses import dataclass

def get_env_var(name, default=None):
    if default is not None:
        try:
            return os.environ[name]
        except KeyError:
            logging.warn(f"Environment variable {name} not set. Using default: {default}")
            return default
    else:
        try:
            return os.environ[name]
        except KeyError:
            logging.critical(f"Environment variable {name} not set.")

@dataclass
class Config:
    secret_arn                = get_env_var('SECRET_ARN')
    acm_certificate_arn       = get_env_var('ACM_CERTIFICATE_ARN')

    keyname_certificate       = get_env_var('KEYNAME_CERTIFICATE', 'CERTIFICATE')
    keyname_private_key       = get_env_var('KEYNAME_PRIVATE_KEY', 'CERTIFICATE_PRIVATE_KEY')
    keyname_certificate_chain = get_env_var('KEYNAME_CERTIFICATE_CHAIN', 'CERTIFICATE_CHAIN')

