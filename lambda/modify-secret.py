import boto3
import json
import logging
import time

import config

config = config.Config()
session = boto3.Session()

client = session.client('secretsmanager')
secret_value = client.get_secret_value(SecretId=config.secret_arn)

secret = json.loads(secret_value['SecretString'])
secret['time'] = time.time()

client.put_secret_value(SecretId=config.secret_arn, SecretString=json.dumps(secret))
