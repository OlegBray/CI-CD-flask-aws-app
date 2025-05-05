import boto3
import json
from botocore.exceptions import ClientError


def get_secret():
    secret_name = "rds!db-777ab260-d218-40d6-8bff-a5f247435ce3"
    region_name = "il-central-1"

    session = boto3.session.Session()

    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        raise e
    
    secret = get_secret_value_response['SecretString']
    secret_dict = json.loads(secret)
    return(secret_dict)

get_secret()