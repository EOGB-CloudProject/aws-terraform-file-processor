\#  Procesador de Archivos Serverless (Versión Terraform)



Este proyecto automatiza el despliegue de una arquitectura Serverless orientada a eventos en AWS utilizando \*\*Infraestructura como Código (IaC)\*\* con Terraform.



\##  Arquitectura Desplegada

\* \*\*AWS S3:\*\* Bucket configurado para la recepción de archivos.

\* \*\*AWS Lambda:\*\* Función en Python (comprimida y desplegada automáticamente por Terraform) para extraer metadatos.

\* \*\*Amazon DynamoDB:\*\* Tabla NoSQL con facturación bajo demanda (Pay-Per-Request).

\* \*\*AWS IAM:\*\* Implementación estricta del Principio de Menor Privilegio, limitando los permisos de la Lambda exclusivamente a los recursos necesarios.



\## Requisitos Previos

\* Terraform instalado en tu máquina local.

\* Credenciales de AWS configuradas.



\## Instrucciones de Despliegue



1\. Inicializa el directorio de trabajo de Terraform:

&#x20;  `terraform init`

2\. Revisa los recursos que se van a crear:

&#x20;  `terraform plan`

3\. Despliega la infraestructura en tu cuenta de AWS:

&#x20;  `terraform apply`



Para asegurar que no existan cargos no deseados en la cuenta de AWS, toda la arquitectura puede ser eliminada con un solo comando:

`terraform destroy`

