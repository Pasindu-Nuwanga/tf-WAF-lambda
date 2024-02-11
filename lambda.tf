locals {
  zip_file_location = "outputs/lambda_function.zip"
}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = local.zip_file_location
}


resource "aws_lambda_function" "test_lambda" {
  filename      = local.zip_file_location
  function_name = "lambda_function_wafip"
  role          = aws_iam_role.wafip_lambda_role.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256(local.zip_file_location)

  runtime = "python3.9"
  timeout = 10

  layers = ["arn:aws:lambda:us-east-1:336392948345:layer:AWSSDKPandas-Python39:1"]

  environment {
    variables = {
      WAF_IP_SET_ID_1 = aws_wafv2_ip_set.ip_set_01.id
      WAF_IP_SET_ID_2 = aws_wafv2_ip_set.ip_set_02.id
    }
  }
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

