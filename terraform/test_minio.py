import boto3
from botocore.config import Config

# Maak een MinIO client
s3_client = boto3.client(
    's3',
    endpoint_url='http://localhost:9000',
    aws_access_key_id='admin',
    aws_secret_access_key='JKjkl<F8>7435fHGF*@)status#KKD',
    aws_session_token=None,
    config=Config(signature_version='s3v4'),
    verify=False
)

# List buckets
response = s3_client.list_buckets()
buckets = [bucket['Name'] for bucket in response['Buckets']]
print(f"Found buckets: {buckets}")

# List objects in test-bucket
objects = s3_client.list_objects_v2(Bucket='test-bucket')
if 'Contents' in objects:
    for obj in objects['Contents']:
        print(f"Found object: {obj['Key']}, size: {obj['Size']} bytes")
