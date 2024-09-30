resource "aws_iam_role" "lambda-role" {
  name = "${var.function_name}-aws-lambda-role-${var.environment}-${var.random_hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_policy" {
  role       = aws_iam_role.lambda-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "eks_workernode_policy" {
  count      = var.attach_eks_policy ? 1 : 0
  role       = aws_iam_role.lambda-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  count      = var.attach_cloudwatch_policy ? 1 : 0
  role       = aws_iam_role.lambda-role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatchlogs_policy" {
  count      = var.attach_cloudwatch_policy ? 1 : 0
  role       = aws_iam_role.lambda-role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  count      = var.attach_lambda_policy ? 1 : 0
  role       = aws_iam_role.lambda-role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

resource "aws_lambda_function" "lambda" {
  function_name = "${var.function_name}-${var.environment}-${var.random_hex}"
  package_type  = "Image"
  architectures = ["x86_64"]
  image_uri     = "${var.container_registry}/${var.container_repository}:${var.container_image_tag}"
  memory_size   = var.ram_mib
  timeout       = var.timeout_s
  role          = aws_iam_role.lambda-role.arn

  environment {
    variables = {
      EKS_CLUSTER_NAME = var.eks_cluster_name
      REGION           = var.region
      ECR_URI          = var.container_registry
      DB_API_URL       = var.db_api_url
      ROUTE53_DOMAIN   = var.route53_domain
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda-cloudwath-log-group" {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = 30
}

resource "aws_lambda_function_url" "lambda-url" {
  function_name      = aws_lambda_function.lambda.function_name
  authorization_type = "NONE"

  cors {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
  }
}

resource "aws_eks_access_entry" "eks-access-entry" {
  count         = var.attach_eks_policy ? 1 : 0
  cluster_name  = var.eks_cluster_name
  principal_arn = aws_iam_role.lambda-role.arn
}

resource "aws_eks_access_policy_association" "eks-access-policy" {
  count         = var.attach_eks_policy ? 1 : 0
  cluster_name  = var.eks_cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_iam_role.lambda-role.arn

  access_scope {
    type = "cluster"
  }
}
