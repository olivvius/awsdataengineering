import boto3
import pandas as pd
import sqlalchemy

s3 = boto3.client('s3')
s3_resource = boto3.resource('s3')
ssm = boto3.client('ssm')

def get_parameter(name):
    response = ssm.get_parameter(Name=name, WithDecryption=True)
    return response['Parameter']['Value']

def lambda_handler(event, context):
    bucket = 'bucket-data-engineering-23233108'
    prefix = 'input/'
    host = get_parameter('/app/db/host')
    port = int(get_parameter('/app/db/port').split(':')[0])
    dbname = get_parameter('/app/db/name')
    engine = sqlalchemy.create_engine(f'mysql+pymysql://<username>:<password>@{host}:{port}/{dbname}')
    conn = engine.connect()
    # create table users if not exists
    conn.execute('CREATE TABLE IF NOT EXISTS USERS (name VARCHAR(255), age INT)') 
    

    for obj in s3.list_objects(Bucket=bucket, Prefix=prefix)['Contents']:
        if obj['Key'].endswith('.csv'):
            data = s3.get_object(Bucket=bucket, Key=obj['Key'])
            df = pd.read_csv(data['Body'])
            df.to_sql('USERS', con=engine, if_exists='append', index=False)

    return {
        'statusCode': 200,
        'body': 'Data loaded to RDS successfully'
    }