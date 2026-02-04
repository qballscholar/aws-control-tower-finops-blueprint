terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  alias  = "management"
  region = var.management_region

  default_tags {
    tags = var.default_tags
  }
}

variable "management_region" {
  type        = string
  default     = "us-east-1"
  description = "Home region for Control Tower, Config, CUR, and FinOps tooling."
}

variable "platform_admin_principal_arn" {
  type        = string
  description = "Trusted AWS principal allowed to assume PlatformAdminRole."
}

variable "default_tags" {
  type        = map(string)
  description = "Org-wide default tags aligned to FinOps tagging policy."
  default = {
    CostCenter  = "FINOPS-GOV"
    Environment = "org-root"
    Owner       = "platform-team"
  }
}

variable "finops_email" {
  type        = string
  description = "Email address for FinOps alerts and notifications"
}

data "aws_iam_policy_document" "platform_admin" {
  statement {
    sid    = "AllowOrgAndFinOpsControlPlane"
    effect = "Allow"

    actions = [
      "organizations:*",
      "controltower:*",
      "config:*",
      "servicecatalog:*",
      "cur:*",
      "ce:*",
      "budgets:*",
      "ce:GetCostAndUsage",
      "ce:GetRightsizingRecommendation"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "platform_admin" {
  provider = aws.management

  name   = "PlatformAdminControlPlane"
  policy = data.aws_iam_policy_document.platform_admin.json
}

resource "aws_iam_role" "platform_admin" {
  provider = aws.management

  name               = "PlatformAdminRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = var.platform_admin_principal_arn
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "platform_admin" {
  provider = aws.management

  role       = aws_iam_role.platform_admin.name
  policy_arn = aws_iam_policy.platform_admin.arn
}

# Customize

# platform_admin_principal_arn → break‑glass admin or an SSO permission set ARN.
# default_tags → align with your tag dictionary.