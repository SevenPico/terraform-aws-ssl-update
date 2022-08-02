#!/bin/bash

export AWS_SDK_LOAD_CONFIG=1
export SECRET_ARN=arn:aws:secretsmanager:us-east-1:111363027042:secret:sfc-dev-ssl-certificate-secret-2022072619333155190000000e-yS6dWo

python main.py
