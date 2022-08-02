import boto3
import json
import logging

import config

logging.basicConfig(level=logging.INFO)

config = config.Config()
session = boto3.Session()

def lambda_handler(event, context):
    logging.info(event)
    logging.info(context)

    acm_import()


def load_secret():
    client = session.client('secretsmanager')
    secret_value = client.get_secret_value(SecretId=config.secret_arn)

    # FIXME - handle
    # SecretsManager.Client.exceptions.ResourceNotFoundException
    # SecretsManager.Client.exceptions.InvalidParameterException
    # SecretsManager.Client.exceptions.InvalidRequestException
    # SecretsManager.Client.exceptions.DecryptionFailure
    # SecretsManager.Client.exceptions.InternalServiceError

    secret = json.loads(secret_value['SecretString'])

    cert        = secret[config.keyname_certificate]
    private_key = secret[config.keyname_private_key]
    cert_chain  = secret[config.keyname_certificate_chain]

    return cert, private_key, cert_chain

def acm_import():
    client = session.client('acm')
    cert, private_key, cert_chain = load_secret()

    client.import_certificate(
        CertificateArn=config.acm_certificate_arn,
        Certificate=cert,
        PrivateKey=private_key,
        CertificateChain=cert_chain,
    )

    # FIXME - handle
    # ACM.Client.exceptions.ResourceNotFoundException
    # ACM.Client.exceptions.LimitExceededException
    # ACM.Client.exceptions.InvalidTagException
    # ACM.Client.exceptions.TooManyTagsException
    # ACM.Client.exceptions.TagPolicyException
    # ACM.Client.exceptions.InvalidParameterException
    # ACM.Client.exceptions.InvalidArnException

def ecs_task_restart():
    pass

def ssm_ssl_command():
    pass

lambda_handler(None, None)
