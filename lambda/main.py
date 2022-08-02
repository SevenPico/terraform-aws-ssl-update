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

    if config.secret_arn is not None:
        acm_import()

    if config.ssm_ssl_update_command is not None:
        ssm_ssl_update_command()

    if config.ecs_cluster_arn is not None:
        ecs_service_update()


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

def ssm_ssl_update_command():
    client = session.client('ssm')

    response = client.send_command(
        DocumentName='AWS-RunShellScript',
        Targets=[{
            'Key': config.ssm_target_key,
            'Values': [config.ssm_target_value] # TODO - support array here?
        }],
        Parameters={
            'commands': [config.ssl_update_command]
        },
    )

    # FIXME - handle
    # SSM.Client.exceptions.DuplicateInstanceId
    # SSM.Client.exceptions.InternalServerError
    # SSM.Client.exceptions.InvalidInstanceId
    # SSM.Client.exceptions.InvalidDocument
    # SSM.Client.exceptions.InvalidDocumentVersion
    # SSM.Client.exceptions.InvalidOutputFolder
    # SSM.Client.exceptions.InvalidParameters
    # SSM.Client.exceptions.UnsupportedPlatformType
    # SSM.Client.exceptions.MaxDocumentSizeExceeded
    # SSM.Client.exceptions.InvalidRole
    # SSM.Client.exceptions.InvalidNotificationConfig


def ecs_service_update():
    client = session.client('ecs')

    for service in config.ecs_service_arns:
        response = client.update_service(
            cluster='string',
            service='string',
            forceNewDeployment=True
            ]
        )

    # FIXME - handle
    # ECS.Client.exceptions.ServerException
    # ECS.Client.exceptions.ClientException
    # ECS.Client.exceptions.InvalidParameterException
    # ECS.Client.exceptions.ClusterNotFoundException
    # ECS.Client.exceptions.ServiceNotFoundException

    task_arns = response['taskArns']

lambda_handler(None, None)
