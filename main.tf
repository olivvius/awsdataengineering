provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "bucket-data-engineering" {
  bucket = "bucket-data-engineering-23233108"
  acl    = "private"
}

resource "aws_s3_bucket_object" "input_folder" {
  bucket = aws_s3_bucket.bucket-data-engineering.id
  key    = "input/"
}

resource "aws_s3_bucket_object" "output_folder" {
  bucket = aws_s3_bucket.bucket-data-engineering.id
  key    = "output/"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_s3_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "s3:GetObject",
        "s3:PutObject"
      ],
      Effect = "Allow",
      Resource = [
        "${aws_s3_bucket.bucket-data-engineering.arn}/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_role_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_role.name
}



resource "aws_lambda_function" "my_lambda" {
  function_name    = "my_lambda_function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  filename         = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")
}

resource "aws_ecr_repository" "my_ecr_repo" {
  name = "mon-registre-ecr"
}

resource "aws_db_instance" "default" {
  identifier             = "mydb"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  username               = "admin"
  password               = "admin1234"
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
}

resource "aws_ssm_parameter" "DB_HOST" {
  name  = "/app/db/host"
  type  = "String"
  value = aws_db_instance.default.endpoint
}

resource "aws_ssm_parameter" "DB_PORT" {
  name  = "/app/db/port"
  type  = "String"
  value = tostring(aws_db_instance.default.port)
}

resource "aws_ssm_parameter" "DB_NAME" {
  name  = "/app/db/name"
  type  = "String"
  value = "aws_db_instance.default.name"
}

resource "aws_lambda_layer_version" "sqlalchemy" {
  filename            = "python.zip"
  layer_name          = "sqlalchemy"
  source_code_hash    = filebase64sha256("python.zip")
  compatible_runtimes = ["python3.11"]
}

resource "aws_iam_role" "s3tords_lambda_role" {
  name = "s3tords_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "s3tords_lambda_policy" {
  name = "s3tords_lambda_policy"
  role = aws_iam_role.s3tords_lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::bucket-data-engineering-23233108",
          "arn:aws:s3:::bucket-data-engineering-23233108/*",
        ]
      },
      {
        Action = [
          "ssm:GetParameter",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:Connect",
        ]
        Effect   = "Allow"
        Resource = aws_db_instance.default.arn
      },
    ]
  })
}

resource "aws_lambda_function" "s3tords" {
  function_name    = "s3tords"
  role             = aws_iam_role.s3tords_lambda_role.arn
  handler          = "s3tords.lambda_handler"
  runtime          = "python3.11"
  filename         = "s3tords.zip"
  source_code_hash = filebase64sha256("s3tords.zip")

  layers = [
    "arn:aws:lambda:us-east-1:336392948345:layer:AWSSDKPandas-Python39:12",
    aws_lambda_layer_version.sqlalchemy.arn
  ]

  timeout = 30
}