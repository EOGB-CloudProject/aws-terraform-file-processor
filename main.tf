terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configuramos el proveedor de AWS y la región
provider "aws" {
  region = "us-east-1" 
}
# Creamos el Bucket de S3
resource "aws_s3_bucket" "bucket_procesador" {
  bucket = "mi-procesador-serverless-eogb-2026"
  
  tags = {
    Environment = "Dev"
    Project     = "Portafolio"
  }
}
# Creamos la tabla de DynamoDB
resource "aws_dynamodb_table" "tabla_procesador" {
  name         = "ProcesadorArchivos-tf"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Environment = "Dev"
    Project     = "Portafolio"
  }
}
#  Permiso para que S3 pueda ejecutar la Lambda
resource "aws_lambda_permission" "permitir_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.procesador_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket_procesador.arn
}

# 6. Conectar S3 con Lambda (El gatillo)
resource "aws_s3_bucket_notification" "notificacion_bucket" {
  bucket = aws_s3_bucket.bucket_procesador.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.procesador_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.permitir_s3]
}