# aws-control-tower-finops-blueprint
AWS FinOps landing zone built with Terraform. Implements a 90‑day Inform → Optimize → Operate rollout: Organizations, Control Tower guardrails, Config, CUR, Budgets, Cost Categories, and alerts. Provides a repeatable FinOps foundation with KPIs and optimization sprints.


```markdown
# AWS FinOps 90‑Day Rollout (Terraform‑Driven Landing Zone)

This repository documents a repeatable 90‑day implementation plan to establish **cloud financial management (FinOps) on AWS**, following the **Inform → Optimize → Operate** lifecycle with a **crawl / walk / run** maturity model.[file:2][file:4][file:8]

The plan is implemented as Terraform modules for:

- AWS Organizations and Control Tower guardrails  
- AWS Config (org‑wide), tagging rules, and region guardrails  
- AWS Cost & Usage Report (CUR), Budgets, and cost anomaly alerts  
- AWS Cost Categories for BI/QuickSight and external FinOps tools

---

## Repository Layout

Recommended structure:

```text
.
├── README.md                          # This file
├── modules
│   ├── finops-foundation              # Provider, platform admin IAM, shared vars/tags
│   ├── finops-org                     # Organizations, OUs, SCPs, Control Tower controls
│   ├── finops-config                  # Config recorder, aggregator, rules
│   ├── finops-cur-budgets             # CUR S3 + CUR definitions + Budgets + SNS
│   └── finops-cost-categories         # Cost Categories and tag-based grouping
└── live
    ├── management-account
    │   └── main.tf                    # Wires management account to modules
    └── prod-app1-account
        └── main.tf                    # Example product account wiring
```


### Module Responsibilities

- `modules/finops-foundation`[file:2][file:4]
    - Terraform `required_providers` and `aws` provider.
    - Default tags (FinOps tagging baseline).
    - Platform admin IAM role (`PlatformAdminRole`) and policy.
- `modules/finops-org`[file:1][file:2][file:4]
    - `aws_organizations_organization`.
    - OU layout (e.g., `Prod`, `NonProd`, BU OUs).
    - SCP baseline for allowed regions and required tags.
    - Optional Control Tower controls (`aws_controltower_enabled_control`).
- `modules/finops-config`[file:1][file:2][file:4]
    - AWS Config recorder and delivery channel.
    - Org aggregator (all regions).
    - Config rules for required tags and region restrictions.
- `modules/finops-cur-budgets`[file:2][file:4][file:8]
    - S3 bucket for CUR.
    - `aws_cur_report_definition` with `RESOURCES` + `ATHENA`.
    - SNS topics for Budgets and cost anomalies.
    - Account/tag scoped Budgets with alerts.
- `modules/finops-cost-categories`[file:2][file:4][file:8]
    - Cost Categories (e.g., Application, BU, Environment).
    - Mapping rules combining account and tag dimensions.

---

## Example: `live/management-account/main.tf`

This file wires your management (payer) account into the shared FinOps modules:

```hcl
module "finops_foundation" {
  source = "../../modules/finops-foundation"

  management_region            = "us-east-1"
  platform_admin_principal_arn = "arn:aws:iam::123456789012:role/OrgAdmin"
  finops_email                 = "finops@your-org.com"
}

module "finops_org" {
  source = "../../modules/finops-org"

  management_region = "us-east-1"
  default_tags      = module.finops_foundation.default_tags
}

module "finops_config" {
  source = "../../modules/finops-config"

  management_region = "us-east-1"
  default_tags      = module.finops_foundation.default_tags
}

module "finops_cur_budgets" {
  source = "../../modules/finops-cur-budgets"

  management_region = "us-east-1"
  finops_email      = module.finops_foundation.finops_email
  default_tags      = module.finops_foundation.default_tags
}

module "finops_cost_categories" {
  source = "../../modules/finops-cost-categories"

  default_tags = module.finops_foundation.default_tags
}
```

**Customize when scaling out**

- New BU or product → add an OU and account in `modules/finops-org`, then create a `live/<account>/main.tf` referencing `finops-config` and `finops-cur-budgets`.
- New cost dimensions → extend rules in `modules/finops-cost-categories` and dashboards/queries.

---

## Overall 90‑Day Targets

By Day 90, this stack aims to achieve:[file:2][file:4][file:8]

- FinOps operating model, **RACI**, and 1‑page charter in place.
- Account structure and tagging delivering ≥70–80% **allocatable spend** in CUR.
- Regular reporting, budgets, and at least one optimization sprint fully documented.
- Commitment strategy defined with coverage and utilization targets (Savings Plans / RIs).

---

## Day 1–30: Discover \& Design (Inform – Crawl)

### Week 1–2: Secure Sponsorship \& Baseline

#### 1. FinOps Charter

- **Owner:** FinOps lead
- **Deliverable:** `docs/FinOps-Charter.md` (1 page)[file:3][file:4][file:6][file:8]

Outline:

- Purpose and scope (AWS only, % of spend in scope).
- Roles: Exec sponsor, FinOps lead, Engineering, Finance, Product.
- Statement that this GitHub repo is the **FinOps platform** for governance IaC.

Map the charter’s “platform admin” capability to the `PlatformAdminRole` below.

#### 2. Platform Admin Role (Least Privilege Control Plane)

Module: `modules/finops-foundation`[file:2][file:4]

```hcl
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
```

**Customize**

- `platform_admin_principal_arn` → break‑glass admin or an SSO permission set ARN.
- `default_tags` → align with your tag dictionary.

---

### Week 3–4: Define Allocation Model

#### 3. Organizations \& OU Layout

Module: `modules/finops-org`[file:1][file:2][file:4]

```hcl
resource "aws_organizations_organization" "this" {
  aws_service_access_principals = [
    "controltower.amazonaws.com",
    "config.amazonaws.com",
    "cloudtrail.amazonaws.com"
  ]

  feature_set = "ALL"
}

resource "aws_organizations_organizational_unit" "prod" {
  name      = "Prod"
  parent_id = aws_organizations_organization.this.roots.id
}

resource "aws_organizations_organizational_unit" "non_prod" {
  name      = "NonProd"
  parent_id = aws_organizations_organization.this.roots.id
}
```

Add more OUs for BUs or shared services as needed.

#### 4. SCP Baseline (Regions + Required Tags)

Same module: `modules/finops-org`[file:1][file:2][file:4]

```hcl
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
```

**Customize**

- Allowed regions list.
- Required tags per your `Tagging-and-Allocation-Policy.md`.


#### 5. AWS Config Org‑Wide

Module: `modules/finops-config`[file:1][file:2][file:4]

```hcl
resource "aws_iam_role" "config_role" {
  name = "AWSConfigRoleOrg"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

data "aws_iam_policy_document" "config_role" {
  statement {
    effect = "Allow"
    actions = [
      "s3:*",
      "config:*",
      "ec2:Describe*",
      "rds:Describe*",
      "iam:Get*",
      "iam:List*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "config_role" {
  role   = aws_iam_role.config_role.id
  policy = data.aws_iam_policy_document.config_role.json
}

resource "aws_s3_bucket" "config" {
  bucket = "org-config-${data.aws_caller_identity.current.account_id}"
}

resource "aws_config_configuration_recorder" "org" {
  name     = "org-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "org" {
  name           = "org-delivery"
  s3_bucket_name = aws_s3_bucket.config.bucket

  depends_on = [aws_config_configuration_recorder.org]
}

resource "aws_config_configuration_recorder_status" "org" {
  name       = aws_config_configuration_recorder.org.name
  is_enabled = true
}
```

Tag/region Config rules:

```hcl
resource "aws_config_config_rule" "required_tags" {
  name = "required-tags-finops"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode({
    tag1Key = "CostCenter"
    tag2Key = "Environment"
    tag3Key = "Owner"
  })

  scope {
    compliance_resource_types = ["AWS::AllSupported"]
  }

  depends_on = [aws_config_configuration_recorder_status.org]
}

resource "aws_config_config_rule" "approved_regions" {
  name = "approved-regions"

  source {
    owner             = "AWS"
    source_identifier = "REGION_RESTRICTION_CHECK"
  }

  input_parameters = jsonencode({
    allowedRegions = "us-east-1,us-west-2"
  })

  depends_on = [aws_config_configuration_recorder_status.org]
}
```

Config aggregator:

```hcl
resource "aws_iam_role" "config_aggregator" {
  name = "AWSConfigAggregatorRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

data "aws_iam_policy_document" "config_aggregator" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "config:Get*",
      "config:Describe*",
      "config:List*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "config_aggregator" {
  role   = aws_iam_role.config_aggregator.id
  policy = data.aws_iam_policy_document.config_aggregator.json
}

resource "aws_config_configuration_aggregator" "org" {
  name = "org-aggregator"

  organization_aggregation_source {
    role_arn    = aws_iam_role.config_aggregator.arn
    all_regions = true
  }
}
```


---

## CUR, Budgets, and Anomaly Alerts

Module: `modules/finops-cur-budgets`[file:2][file:4][file:8]

### CUR S3 + Report

```hcl
resource "aws_s3_bucket" "cur" {
  bucket = "finops-cur-${data.aws_caller_identity.current.account_id}"
  acl    = "private"

  tags = merge(var.default_tags, {
    Purpose = "cur-storage"
  })
}

resource "aws_s3_bucket_public_access_block" "cur" {
  bucket = aws_s3_bucket.cur.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cur" {
  bucket = aws_s3_bucket.cur.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_cur_report_definition" "org_cur" {
  report_name = "org-finops-cur"

  time_unit   = "HOURLY"
  format      = "textORcsv"
  compression = "GZIP"

  additional_schema_elements = [
    "RESOURCES"
  ]

  s3_bucket = aws_s3_bucket.cur.bucket
  s3_region = var.management_region
  s3_prefix = "cur/"

  report_versioning    = "CREATE_NEW_REPORT"
  additional_artifacts = ["ATHENA"]
}
```


### Budgets + Alerts

```hcl
resource "aws_sns_topic" "finops_budgets" {
  name = "finops-budgets-alerts"

  tags = merge(var.default_tags, {
    Purpose = "budget-alerts"
  })
}

resource "aws_sns_topic_subscription" "finops_budgets_email" {
  topic_arn = aws_sns_topic.finops_budgets.arn
  protocol  = "email"
  endpoint  = var.finops_email
}

resource "aws_budgets_budget" "account_monthly" {
  name        = "acct-${data.aws_caller_identity.current.account_id}-monthly"
  budget_type = "COST"
  time_unit   = "MONTHLY"

  limit_amount = "5000"
  limit_unit   = "USD"

  cost_filters = {
    "LinkedAccount" = [data.aws_caller_identity.current.account_id]
  }

  time_period_start = "2024-01-01_00:00"

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "FORECASTED"
    subscriber_sns_topic_arns = [aws_sns_topic.finops_budgets.arn]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.finops_budgets.arn]
  }
}
```

Tag‑scoped budget:

```hcl
variable "product_tag_value" {
  type        = string
  description = "Product tag value (e.g. 'loan-origination')."
}

resource "aws_budgets_budget" "product_monthly" {
  name        = "prod-${var.product_tag_value}-monthly"
  budget_type = "COST"
  time_unit   = "MONTHLY"

  limit_amount = "2000"
  limit_unit   = "USD"

  cost_filters = {
    "TagKeyValue" = ["Product$${var.product_tag_value}"]
  }

  time_period_start = "2024-01-01_00:00"

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "FORECASTED"
    subscriber_sns_topic_arns = [aws_sns_topic.finops_budgets.arn]
  }
}
```


### Anomaly Alerts SNS

```hcl
resource "aws_sns_topic" "finops_anomalies" {
  name = "finops-cost-anomalies"

  tags = merge(var.default_tags, {
    Purpose = "cost-anomaly-alerts"
  })
}

resource "aws_sns_topic_subscription" "finops_anomalies_email" {
  topic_arn = aws_sns_topic.finops_anomalies.arn
  protocol  = "email"
  endpoint  = var.finops_email
}
```

Configure AWS Cost Anomaly Detection in the console to send notifications to `finops_anomalies`.

---

## Cost Categories Module

Module: `modules/finops-cost-categories`[file:2][file:4][file:8]

```hcl
resource "aws_ce_cost_category" "application" {
  name         = "Application"
  rule_version = "CostCategoryExpression.v1"

  rule {
    value = "LoanOrigination"

    rule {
      and {
        dimension {
          key           = "LINKED_ACCOUNT"
          values        = [data.aws_caller_identity.current.account_id]
          match_options = ["EQUALS"]
        }
        tags {
          key    = "Product"
          values = ["loan-origination"]
        }
      }
    }
  }

  default_value = "Other"
}
```

Add more rules for other products/BUs.

---

## Metrics \& Maturity Targets

Key metrics to track across Day 30 / 60 / 90:[file:4][file:8][file:9]


| Metric | Day 30 (Crawl) | Day 60 (Walk) | Day 90 (Run) |
| :-- | :-- | :-- | :-- |
| Spend Allocation | ≥50% allocatable | ≥70% allocatable | ≥80–90% allocatable |
| Forecast Variance | ±20% MoM | ±15% MoM | ±12% MoM |
| Optimization Savings | \$5–10K/mo identified | \$10–20K/mo realized | Continuous pipeline + automation |
| Commitment Coverage | Baseline documented | 50–60% coverage | 60–70% coverage target |
| Commitment Utilization | N/A | Tracking started | ≥90% utilization |
| Eng. Engagement | 2–3 pilot teams | 5+ teams | Org‑wide adoption |


---

## How to Use This Repo (New Team Onboarding)

1. **Clone** the repository.
2. Review `README.md` and `modules/` READMEs.
3. Update `live/management-account/main.tf` with your account IDs, ARNs, and email.
4. Run `terraform init && terraform apply` in `live/management-account`.
5. Create docs (`docs/FinOps-Charter.md`, RACI, Tagging Policy, KPIs) referencing this infrastructure.
6. Onboard pilot accounts under `live/<account>/main.tf`, referencing relevant modules.
7. Follow the 90‑day cadence: Inform (Day 1–30), Optimize (Day 31–60), Operate (Day 61–90).

---

## Acronym Table

| Acronym | Full Term | Definition |
| :-- | :-- | :-- |
| AZ | Availability Zone | Isolated location within an AWS Region for redundancy.[file:8] |
| BU | Business Unit | Organizational division (e.g., Retail Lending, Consumer Banking).[file:8] |
| CFO | Chief Financial Officer | Executive responsible for financial planning and risk management.[file:8] |
| CIO | Chief Information Officer | Executive responsible for IT strategy and operations.[file:8] |
| CLIN | Contract Line Item Number | Line item in large contracts for tracking obligations.[file:1][file:8] |
| CTO | Chief Technology Officer | Executive responsible for technology strategy and engineering.[file:8] |
| CUR | Cost \& Usage Report | AWS detailed billing export with hourly/daily granularity.[file:2][file:4][file:8] |
| EBS | Elastic Block Store | AWS persistent block storage for EC2 instances.[file:8] |
| EC2 | Elastic Compute Cloud | AWS virtual machine service.[file:8] |
| EDP | Enterprise Discount Program | AWS volume-based discount agreement (also called PPA).[file:4][file:8] |
| EIP | Elastic IP | AWS static public IP address.[file:8] |
| EKS | Elastic Kubernetes Service | AWS managed Kubernetes service.[file:8] |
| Fargate | AWS Fargate | Serverless compute engine for containers (ECS/EKS).[file:8] |
| FP\&A | Financial Planning \& Analysis | Finance function for budgeting and forecasting.[file:8] |
| IAM | Identity \& Access Management | AWS service for users, roles, and policies.[file:8] |
| IA | Infrequent Access | S3 storage class for infrequently accessed data.[file:8] |
| IOPS | Input/Output Ops Per Second | Storage performance metric.[file:8] |
| KPI | Key Performance Indicator | Metric for measuring progress against objectives.[file:3][file:4][file:8] |
| Lambda | AWS Lambda | AWS serverless function compute service.[file:8] |
| LoE | Level of Effort | Estimated work required (low/medium/high).[file:8] |
| MoM | Month-over-Month | Comparison metric from one month to the next.[file:8] |
| MTD | Month-to-Date | Accumulated total from start of month to present.[file:8] |
| PPA | Private Pricing Addendum | AWS enterprise discount agreement (EDP).[file:4][file:8] |
| RACI | Responsible, Accountable, etc. | Matrix defining roles and decision authority.[file:1][file:4][file:8] |
| RDS | Relational Database Service | AWS managed relational database service.[file:8] |
| RI | Reserved Instance | Discounted commitment for specific instance type/term.[file:4][file:8] |
| S3 | Simple Storage Service | AWS object storage service.[file:8] |
| SCP | Service Control Policy | AWS Organizations policy for account-level permission guardrails.[file:2][file:8] |
| SP | Savings Plan | Discounted commitment to minimum spend per hour.[file:4][file:8] |
| TTL | Time To Live | Expiration time for temporary resources (for auto-cleanup).[file:1][file:8] |


---
