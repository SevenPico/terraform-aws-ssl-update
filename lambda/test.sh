#!/bin/bash

export AWS_SDK_LOAD_CONFIG=1

export SECRET_ARN=arn:aws:secretsmanager:us-east-1:249974707517:secret:sevenpico-example-ssl-secret-20220802123247282900000001-S3WepF
export ACM_CERTIFICATE_ARN=arn:aws:acm:us-east-1:249974707517:certificate/9f100995-85d3-4a77-9e2e-c232b30e86a1

export KEYNAME_CERTIFICATE=CERTIFICATE
export KEYNAME_PRIVATE_KEY=CERTIFICATE_PRIVATE_KEY
export KEYNAME_CERTIFICATE_CHAIN=CERTIFICATE_CHAIN

#python main.py
python modify-secret.py
