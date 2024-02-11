resource "aws_iam_role_policy" "wafip_lambda_policy" {
  name = "waf_lambda_policy"
  role = aws_iam_role.wafip_lambda_role.id

  policy = file("IAM/lambda-policy.json")
}


resource "aws_iam_role" "wafip_lambda_role" {
  name = "waf_lambda_role"

  assume_role_policy = file("IAM/lambda-assume-role-policy.json")
}