data "aws_iam_policy_document" "scp_baseline" {
  statement {
    sid    = "DenyUnsupportedRegions"
    effect = "Deny"

    actions   = ["*"]
    resources = ["*"]

    condition = {
      StringNotEquals = {
        "aws:RequestedRegion" = [
          "us-east-1",
          "us-west-2"
        ]
      }
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }

  statement {
    sid    = "DenyMissingFinOpsTags"
    effect = "Deny"

    actions   = ["ec2:RunInstances", "rds:CreateDBInstance", "eks:CreateCluster"]
    resources = ["*"]

    condition = {
      Null = {
        "aws:RequestTag/CostCenter"  = "true",
        "aws:RequestTag/Environment" = "true",
        "aws:RequestTag/Owner"       = "true"
      }
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_organizations_policy" "scp_baseline" {
  name        = "FinOps-LeastPrivilege-Baseline"
  description = "Restrict regions and require FinOps tags for resource creation."
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.scp_baseline.json
}

resource "aws_organizations_policy_attachment" "scp_root" {
  policy_id = aws_organizations_policy.scp_baseline.id
  target_id = aws_organizations_organization.this.roots.id
}

# Customize

# Allowed regions list.
# Required tags per your Tagging-and-Allocation-Policy