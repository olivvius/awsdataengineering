import boto3
import pandas as pd
from io import StringIO

aws_access_key = ""
aws_secret_key = ""
region_name = "us-east-1"

bucket_name = "bucket-data-engineering-23233108"
input_key = "input/data.csv"
output_key = "output/average.txt"

s3 = boto3.client("s3", aws_access_key_id=aws_access_key, aws_secret_access_key=aws_secret_key, region_name=region_name)

csv_object = s3.get_object(Bucket=bucket_name, Key=input_key)
csv_content = csv_object["Body"].read().decode("utf-8")

data = pd.read_csv(StringIO(csv_content))

average_age = data["age"].mean()

output_content = f"Average age: {average_age}"

s3.put_object(Bucket=bucket_name, Key=output_key, Body=output_content)
