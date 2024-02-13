locals {
  zip_file_location = "outputs/lambda_function.zip"
}

locals {
  source_code_hash = fileexists("lambda_function.zip") ? filebase64sha256("lambda_function.zip") : data.archive_file.lambda_function.output_base64sha256
}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = local.zip_file_location
}

resource "aws_wafv2_ip_set" "ip_set_01" {
  name               = "Test-Ips1"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"

  tags = {
    name = "test-ip-set-01"
  }
}

resource "aws_wafv2_ip_set" "ip_set_02" {
  name               = "Test-Ips2"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"

  tags = {
    name = "test-ip-set-02"
  }
}

resource "aws_lambda_function" "test_lambda" {
  filename      = local.zip_file_location
  function_name = "lambda_function_wafip"
  role          = aws_iam_role.wafip_lambda_role.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = local.source_code_hash

  runtime = "python3.9"
  timeout = 10

  layers = ["arn:aws:lambda:us-east-1:336392948345:layer:AWSSDKPandas-Python39:1"]

  environment {
    variables = {
      WAF_IP_SET_ID_1 = aws_wafv2_ip_set.ip_set_01.id
      WAF_IP_SET_ID_2 = aws_wafv2_ip_set.ip_set_02.id
    }
  }

  depends_on = [
    aws_wafv2_ip_set.ip_set_01,
    aws_wafv2_ip_set.ip_set_02
  ]
}

resource "aws_lambda_function_event_invoke_config" "test_event" {
  function_name = aws_lambda_function.test_lambda.function_name
  qualifier     = "$LATEST"
}