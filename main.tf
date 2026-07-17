terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" 
}

# 1. Creamos el Bucket de S3
resource "aws_s3_bucket" "bucket_procesador" {
  bucket = "mi-procesador-serverless-eogb-2026"
  
  tags = {
    Environment = "Dev"
    Project     = "Portafolio"
  }
}

# 2. Creamos la tabla de DynamoDB
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

# 3. Creamos el Rol de IAM para la Lambda (El "gafete")
resource "aws_iam_role" "lambda_role" {
  name = "rol_lambda_procesador_tf"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# 4. Le damos permisos al Rol (Incluyendo crear Logs en CloudWatch)
resource "aws_iam_role_policy" "lambda_policy" {
  name = "politica_lambda_procesador_tf"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = ["dynamodb:PutItem"]
        Resource = aws_dynamodb_table.tabla_procesador.arn
      },
      {
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.bucket_procesador.arn}/*"
      }
    ]
  })
}

# 5. Comprimimos el archivo Python
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

# 6. Creamos la Función Lambda
resource "aws_lambda_function" "procesador_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "ProcesadorArchivosS3-TF"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# 7. Permiso para que S3 pueda ejecutar la Lambda
resource "aws_lambda_permission" "permitir_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.procesador_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket_procesador.arn
}

# 8. Conectar S3 con Lambda (El gatillo)
resource "aws_s3_bucket_notification" "notificacion_bucket" {
  bucket = aws_s3_bucket.bucket_procesador.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.procesador_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.permitir_s3]
}