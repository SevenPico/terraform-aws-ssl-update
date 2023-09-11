import boto3
import botocore.exceptions
import json
import logging

import config

logging.basicConfig(level=logging.INFO)

config = config.Config()
session = boto3.Session()


def lambda_handler(event, context):
    logging.info(event)
    logging.info(context)

    try:
        if config.secret_arn is not None:
            logging.info('Re-importing ACM certificate')
            acm_import()
        else:
            logging.info(f'ACM certificate import')
    except:
        logging.error("Error Importing ACM Certificate")

    if config.ssm_ssl_adhoc_command is not None:
        logging.info('Issuing SSM SSL certificate update commands')
        ssm_ssl_adhoc_command()
    else:
        logging.info("SSM SSL certificate update commands not enabled")

    if config.ecs_cluster_arn is not None:
        logging.info('Starting ECS service updates')
        ecs_service_update()
    else:
        logging.info("ECS service updates not enabled")

    if config.ssm_ssl_named_document is not None:
        logging.info('Issuing SSM SSL Named document')
        ssm_ssl_named_document()
    else:
        logging.info("SSM SSL Named document not enabled")


def load_secret():
    client = session.client('secretsmanager')

    logging.info(f"Reading secret: {config.secret_arn}")
    secret_value = client.get_secret_value(SecretId=config.secret_arn)

    # FIXME - handle
    # SecretsManager.Client.exceptions.ResourceNotFoundException
    # SecretsManager.Client.exceptions.InvalidParameterException
    # SecretsManager.Client.exceptions.InvalidRequestException
    # SecretsManager.Client.exceptions.DecryptionFailure
    # SecretsManager.Client.exceptions.InternalServiceError

    logging.info(f"Parsing secret: {config.secret_arn}")
    secret = json.loads(secret_value['SecretString'])

    cert = secret[config.keyname_certificate]
    private_key = secret[config.keyname_private_key]
    cert_chain = secret[config.keyname_certificate_chain]

    return cert, private_key, cert_chain


def acm_import():
    client = session.client('acm')

    cert, private_key, cert_chain = load_secret()

    try:
        client.import_certificate(
            CertificateArn=config.acm_certificate_arn,
            Certificate=cert,
            PrivateKey=private_key,
            CertificateChain=cert_chain,
        )
        logging.info("Successfully imported ACM certificate.")
    except botocore.exceptions.ClientError as e:
        error_code = e.response.get("Error", {}).get("Code", "Unknown")
        error_message = e.response.get("Error", {}).get("Message", "An error occurred.")

        if error_code == "ResourceNotFoundException":
            logging.error("ACM resource not found.")
        elif error_code == "LimitExceededException":
            logging.error("ACM limit exceeded.")
        elif error_code == "InvalidTagException":
            logging.error("Invalid ACM tag.")
        elif error_code == "TooManyTagsException":
            logging.error("Too many ACM tags.")
        elif error_code == "TagPolicyException":
            logging.error("ACM tag policy error.")
        elif error_code == "InvalidParameterException":
            logging.error("Invalid ACM parameter.")
        elif error_code == "InvalidArnException":
            logging.error("Invalid ACM ARN.")
        else:
            logging.error(f"ACM Error: {error_code} - {error_message}")

    acm_certificate_arn_replicas = json.loads(config.acm_certificate_arn_replicas)
    cert, private_key, cert_chain = load_secret()
    for region, arn in acm_certificate_arn_replicas.items():
        region_session = boto3.Session(region_name=region)
        try:
            print(f' Importing ACM Certificate Replica {arn} in {region} ')
            region_client = region_session.client('acm')
            region_client.import_certificate(
                CertificateArn=arn,
                Certificate=cert,
                PrivateKey=private_key,
                CertificateChain=cert_chain,
            )
            logging.info(f'Successfully imported ACM Replica certificate')
        except Exception as e:
            logging.error(f"Error importing ACM Replica certificate: {str(e)}")


def ssm_ssl_adhoc_command():
    client = session.client('ssm')

    response = client.send_command(
        DocumentName='AWS-RunShellScript',
        Targets=[{
            'Key': config.ssm_target_key,
            'Values': config.ssm_target_values
        }],
        Parameters={
            'commands': [config.ssm_ssl_adhoc_command]
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


def ssm_ssl_named_document():
    client = session.client('ssm')

    # Run the SSM Document on the instances that match the specified tag
    ssm_document = boto3.client('ssm')

    # Specify the SSM Document to run
    document_name = config.ssm_ssl_named_document

    # Specify the targets to run the SSM Document on
    target_tag_key = config.ssm_target_key
    target_tag_value = config.ssm_target_values

    # Build the target list
    targets = [
        {
            'Key': target_tag_key,
            'Values': target_tag_value
        }
    ]

    logging.info(f"Target_key : {target_tag_key} ssm_document : {document_name} Target_value : {target_tag_value}")
    response = ssm_document.send_command(
        DocumentName=document_name,
        DocumentVersion='$LATEST',
        Targets=targets
    )
    # Get the command ID
    command_id = response['Command']['CommandId']

    print(f"SSM Document {document_name} sent to targets with command ID {command_id}")


def ecs_service_update():
    client = session.client('ecs')

    for service_arn in config.ecs_service_arns:
        logging.info(f"Updating ECS service: {service_arn}")
        response = client.update_service(
            cluster=config.ecs_cluster_arn,
            service=service_arn,
            forceNewDeployment=True
        )

    # FIXME - handle
    # ECS.Client.exceptions.ServerException
    # ECS.Client.exceptions.ClientException
    # ECS.Client.exceptions.InvalidParameterException
    # ECS.Client.exceptions.ClusterNotFoundException
    # ECS.Client.exceptions.ServiceNotFoundException
