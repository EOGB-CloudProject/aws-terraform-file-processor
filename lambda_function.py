import json
import boto3
import uuid
from datetime import datetime

s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

# El nombre EXACTO que le pusiste en Terraform
table = dynamodb.Table('ProcesadorArchivos-tf')

def lambda_handler(event, context):
    try:
        record = event['Records'][0]
        bucket_name = record['s3']['bucket']['name']
        file_key = record['s3']['object']['key']
        file_size = record['s3']['object']['size']
        
        print(f"Procesando archivo: {file_key} del bucket: {bucket_name}")
        
        file_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat()
        
        table.put_item(
            Item={
                'id': file_id,
                'nombre_archivo': file_key,
                'bucket': bucket_name,
                'tamano_bytes': file_size,
                'fecha_procesamiento': timestamp,
                'estado': 'PROCESADO'
            }
        )
        
        return {
            'statusCode': 200,
            'body': json.dumps('Metadatos guardados con éxito en DynamoDB')
        }
        
    except Exception as e:
        print(f"Error procesando el archivo: {str(e)}")
        raise e