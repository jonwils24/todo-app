locals {
  name = var.name
}

####################### API Gateway #######################

resource "aws_apigatewayv2_api" "this_api" {
  name          = "${local.name}-http-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_headers = ["*"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }
}

resource "aws_apigatewayv2_integration" "this_api_integration" {
  api_id           = aws_apigatewayv2_api.this_api.id
  integration_type = "AWS_PROXY"

  integration_method = "ANY"
  integration_uri    = module.this_lambda_function.lambda_function_arn
}

resource "aws_apigatewayv2_route" "this_api_route_any_proxy" {
  api_id    = aws_apigatewayv2_api.this_api.id
  route_key = "ANY /todos/{proxy+}"

  target = "integrations/${aws_apigatewayv2_integration.this_api_integration.id}"
}

resource "aws_apigatewayv2_route" "this_api_route_any" {
  api_id    = aws_apigatewayv2_api.this_api.id
  route_key = "ANY /todos"

  target = "integrations/${aws_apigatewayv2_integration.this_api_integration.id}"
}

resource "aws_apigatewayv2_stage" "this_api_stage" {
  api_id = aws_apigatewayv2_api.this_api.id
  name   = "default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.this_api_stage_log_group.arn
    format = jsonencode(
        {
          httpMethod     = "$context.httpMethod"
          ip             = "$context.identity.sourceIp"
          protocol       = "$context.protocol"
          requestId      = "$context.requestId"
          requestTime    = "$context.requestTime"
          responseLength = "$context.responseLength"
          routeKey       = "$context.routeKey"
          status         = "$context.status"
        }
      )
  }
}

resource "aws_cloudwatch_log_group" "this_api_stage_log_group" {
  name = "${local.name}"
}

####################### Lambda #######################

module "this_lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  function_name = "${local.name}-lambda"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.6"
  lambda_role = aws_iam_role.this_iam_role_for_lambda.arn
  create_role = false

  source_path = [
    "${path.module}/lambdas",
    {
      pip_requirements = "${path.module}/lambdas/requirements.txt"
    }
  ]

  environment_variables = {
    "DYNAMO_TABLE_NAME" = aws_dynamodb_table.this_dynamodb_table.name
  }
}

resource "aws_lambda_permission" "this_lambda_permission" {
  statement_id  = "AllowTodoAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.this_lambda_function.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  source_arn = "${aws_apigatewayv2_api.this_api.execution_arn}/*/*/*"
}

resource "aws_iam_role" "this_iam_role_for_lambda" {
  name = "${local.name}-iam_role_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.this_iam_role_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}

data "aws_iam_policy_document" "this_lambda_dynamodb_access" {
  statement {
    sid = "DynamoDbAccessForLambda"

    actions = [
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Scan"
    ]

    resources = ["${aws_dynamodb_table.this_dynamodb_table.arn}*"]
  }
}

resource "aws_iam_policy" "this_lambda_dynamodb_policy" {
  name   = "DynamoDbAccessForLambda"
  policy = data.aws_iam_policy_document.this_lambda_dynamodb_access.json
}

resource "aws_iam_role_policy_attachment" "this_lambda_dynamodb" {
  role       = aws_iam_role.this_iam_role_for_lambda.name
  policy_arn = aws_iam_policy.this_lambda_dynamodb_policy.arn
}

####################### DynamoDB #######################

resource "aws_dynamodb_table" "this_dynamodb_table" {
  name           = "${local.name}-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
