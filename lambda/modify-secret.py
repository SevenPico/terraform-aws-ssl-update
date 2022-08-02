import boto3
import json
import logging
import time

import config

logging.basicConfig(level=logging.INFO)

config = config.Config()
session = boto3.Session()

client = session.client('secretsmanager')
secret_value = client.get_secret_value(SecretId=config.secret_arn)

# FIXME - handle
# SecretsManager.Client.exceptions.ResourceNotFoundException
# SecretsManager.Client.exceptions.InvalidParameterException
# SecretsManager.Client.exceptions.InvalidRequestException
# SecretsManager.Client.exceptions.DecryptionFailure
# SecretsManager.Client.exceptions.InternalServiceError

secret = json.loads(secret_value['SecretString'])
secret['time'] = time.time()

client.put_secret_value(SecretId=config.secret_arn, SecretString=json.dumps(secret))

# {
# "SecretARN": "arn:aws:secretsmanager:us-east-2:123456789012:secret:production/MyAwesomeAppSecret-AbCdEf",
# "SecretName": "production/MyAwesomeAppSecret",
# "VersionId": "EXAMPLE1-90ab-cdef-fedc-ba987EXAMPLE"
# }
