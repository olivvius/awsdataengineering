import boto3
import csv
import io
import json

def lambda_handler(event, context):
    data = [
        {"Name": "Alice", "Age": 30},
        {"Name": "Bob", "Age": 25},
        {"Name": "Carol", "Age": 40}
    ]

    csv_buffer = io.StringIO()
    csv_writer = csv.DictWriter(csv_buffer, fieldnames=["Name", "Age"])
    csv_writer.writeheader()
    csv_writer.writerows(data)

    s3 = boto3.client("s3")
    csv_buffer.seek(0)
    s3.put_object(Bucket="bucket-data-engineering-23233108", Key="input/data.csv", Body=csv_buffer.getvalue())

    return {
        "statusCode": 200,
        "body": json.dumps("Fichier CSV téléversé avec succès dans S3.")
    }

