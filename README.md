# aws-control-tower-finops-blueprint

# AWS FinOps 90‑Day Rollout (Terraform‑Driven Landing Zone)

AWS FinOps landing zone built with Terraform. Implements a 90‑day **Inform → Optimize → Operate** rollout with Organizations, Control Tower guardrails, Config, CUR, Budgets, Cost Categories, and alerts. Provides a repeatable FinOps foundation with KPIs and optimization sprints.

---

## Quick Navigation

- 📖 **[PROJECT_REVIEW_REPORT.md](PROJECT_REVIEW_REPORT.md)** – Executive summary and remediation details
- 🚀 **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** – Deployment guide and customization
- 🔍 **[REVIEW_DETAILED.md](REVIEW_DETAILED.md)** – Deep dive architectural review
- 📋 **[INDEX.md](INDEX.md)** – Document index and navigation guide

---

## Repository Layout

```text
.
├── README.md                          # This file
├── PROJECT_REVIEW_REPORT.md           # Remediation and validation report
├── QUICK_REFERENCE.md                 # Deployment guide
├── REVIEW_DETAILED.md                 # Architectural deep dive
├── INDEX.md                           # Document navigation index
├── modules
│   ├── finops-foundation              # Provider, IAM, default tags
│   │   ├── platform-admin-role-control-plane.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── (other supporting files)
│   ├── finops-org                     # Organizations, OUs, SCPs
│   │   ├── organizations-ou-layout.tf
│   │   ├── scp-baseline-regions-required-tags.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   ├── finops-config                  # Config recorder, aggregator, rules
│   │   ├── aws-config-org-wide.tf
│   │   ├── config-aggregator.tf
│   │   ├── tag-region-config-rules.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── data-sources.tf
│   ├── finops-cur-budgets             # CUR, Budgets, SNS
│   │   ├── cur-s3-report.tf
│   │   ├── budgets-alerts.tf
│   │   ├── tag-scoped-budget.tf
│   │   ├── anomaly-alerts-sns.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── data-sources.tf
│   └── finops-cost-categories         # Cost Categories
│       ├── cost-categories-module.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       └── data-sources.tf
└── live
    ├── management-account
    │   └── main.tf                    # Wires management account (payer) to all modules
    └── prod-app1-account
        └── main.tf                    # Template for product account (member account)
```

---

## Module Responsibilities

### finops-foundation
- Terraform `required_providers` and `aws` provider
- Default tags (FinOps tagging baseline)
- Platform admin IAM role (`PlatformAdminRole`) with least-privilege permissions
- **Exports:** `default_tags`, `finops_email`, `platform_admin_role_arn`

### finops-org
- `aws_organizations_organization` setup
- OU layout (e.g., `Prod`, `NonProd`, Business Unit OUs)
- SCP baseline for allowed regions and required tags
- Optional Control Tower controls integration
- **Uses:** `default_tags`
- **Exports:** `organization_id`, `root_id`, `prod_ou_id`, `non_prod_ou_id`, `scp_baseline_id`

### finops-config
- AWS Config recorder and delivery channel
- Organization aggregator (all regions)
- Config rules for required tags and region restrictions
- Multi-region compliance visibility
- **Uses:** `default_tags`, `management_region`
- **Exports:** `config_recorder_id`, `config_bucket_name`, `aggregator_arn`, `rule_ids`

### finops-cur-budgets
- S3 bucket for Cost & Usage Report (CUR)
- `aws_cur_report_definition` with `RESOURCES` + `ATHENA` artifacts
- SNS topics for Budgets and cost anomalies
- Account-scoped and tag-scoped Budgets with alerts
- **Uses:** `finops_email`, `default_tags`, `management_region`
- **Exports:** `cur_bucket_name`, `finops_budgets_topic_arn`, `finops_anomalies_topic_arn`, `budget_ids`

### finops-cost-categories
- Cost Categories (e.g., Application, Business Unit, Environment)
- Mapping rules combining account and tag dimensions
- Integration with Cost Explorer and BI tools (QuickSight, etc.)
- **Uses:** `default_tags`
- **Exports:** `cost_category_id`, `cost_category_arn`

---

## Getting Started

### Prerequisites

1. **Terraform** ≥ 1.5.0
2. **AWS CLI** configured with credentials
3. **AWS Account** with Organizations enabled
4. **Permissions:** Break-glass admin or SSO permission set with full organizational access

### Step 1: Clone the Repository

```bash
git clone https://github.com/qballscholar/aws-control-tower-finops-blueprint.git
cd aws-control-tower-finops-blueprint
```

### Step 2: Review Configuration

```bash
# Review the deployment guide
cat QUICK_REFERENCE.md

# Review the architecture
cat REVIEW_DETAILED.md
```

### Step 3: Customize Configuration

Edit `live/management-account/main.tf` and update with your values:

```hcl
module "finops_foundation" {
  source = "../../modules/finops-foundation"

  management_region            = "us-east-1"  # ← Your home region
  platform_admin_principal_arn = "arn:aws:iam::123456789012:role/OrgAdmin"  # ← Your account/role
  finops_email                 = "finops@company.com"  # ← Your FinOps team email
}

# ... rest of module configuration
```

### Step 4: Deploy

```bash
cd live/management-account

# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Apply the configuration
terraform apply

# View outputs
terraform output
```

### Step 5: Validate Deployment

Check AWS console for:
- ✅ Organization created with OUs
- ✅ Config recorder enabled
- ✅ CUR S3 bucket created
- ✅ SNS topics visible (check email confirmations)
- ✅ Cost categories in Cost Explorer
- ✅ PlatformAdminRole created

For detailed validation procedures, see [QUICK_REFERENCE.md](QUICK_REFERENCE.md#validation-checklist).

### Step 6 (Optional): Onboard Product Accounts

Once the management account is operational, you can onboard product/member accounts:

```bash
# 1. Create new AWS account in Organizations
aws organizations create-account --email product-team@company.com --account-name "Product-App1"

# 2. Create directory for product account
mkdir -p live/product-name-account

# 3. Copy template and customize
cp live/prod-app1-account/main.tf live/product-name-account/main.tf

# 4. Update variables in the copied main.tf:
#    - product_name = "your-product"
#    - management_account_id = "123456789012"
#    - finops_email = "product-team@company.com"

# 5. Deploy to product account
cd live/product-name-account
terraform init
terraform apply
```

For detailed product account setup, see [Onboarding Product Accounts](#onboarding-product-accounts) section below.

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

**Customize when scaling out:**
- **New Business Unit or Product:** Add an OU in `modules/finops-org`, create an account in AWS Organizations, then create a `live/<product-account>/main.tf` using the template from `live/prod-app1-account/main.tf`.
- **New Cost Dimensions:** Extend rules in `modules/finops-cost-categories` and update BI dashboards/queries.

See [Onboarding Product Accounts](#onboarding-product-accounts) below for step-by-step instructions.

---Onboarding Product Accounts

### Overview

The management account (`live/management-account/main.tf`) deploys **organization-level** FinOps infrastructure:
- AWS Organizations and OUs
- SCPs and Control Tower guardrails
- Organization-wide Config aggregator
- Shared SNS topics for alerts
- Organization-wide cost categories

**Product accounts** (member accounts under OUs) deploy **account-level** resources:
- Config recorder for compliance tracking
- Product-specific budgets
- Product-specific cost tracking
- Product team SNS subscriptions

### Architecture Difference

```
Management Account (Payer)          Product Accounts (Members)
├── finops-foundation                ├── finops-config
├── finops-org                       ├── finops-cur-budgets
├── finops-config (aggregator)       └── finops-cost-categories
├── finops-cur-budgets (org-wide)
└── finops-cost-categories

↓↓↓ SCPs & Config Aggregator ↓↓↓
```

### Step-by-Step: Add a Product Account

#### 1. Create AWS Account

From the management account:

```bash
# Create the account
aws organizations create-account \
  --email product-team@company.com \
  --account-name "payments-product"

# Get the account ID from the output or:
aws organizations list-accounts --query "Accounts[?Name=='payments-product'].Id" --output text
# Output: 987654321098
```

#### 2. Add to Organizational Unit

```bash
# Get the Prod OU ID
aws organizations list-organizational-units-for-parent \
  --parent-id r-xyz \
  --query "OrganizationalUnits[?Name=='Prod'].Id" --output text

# Move account to OU
aws organizations move-account \
  --account-id 987654321098 \
  --source-parent-id r-xyz \
  --destination-parent-id ou-prod-id
```

#### 3. Set Up Product Account Configuration

Create new directory structure:

```bash
mkdir -p live/payments-account
```

Copy and customize the template:

```bash
cp live/prod-app1-account/main.tf live/payments-account/main.tf
```

Edit `live/payments-account/main.tf`:

```hcl
# Update product name
variable "product_name" {
  type    = string
  default = "payments"  # ← Change this
}

# Update management account ID
variable "management_account_id" {
  type    = string
  default = "123456789012"  # ← Your management account ID
}

# Update product team email
module "finops_cur_budgets_product" {
  # ...
  finops_email = "payments-team@company.com"  # ← Change this
  # ...
}

# Customize product tags
variable "product_tags" {
  default = {
    CostCenter  = "PAYMENTS"         # ← Change
    Environment = "production"
    Owner       = "payments-team"    # ← Change
    Product     = "payments"         # ← Change
  }
}
```

#### 4. Deploy to Product Account

**Option A: From Product Account (with cross-account assume role)**

```bash
cd live/payments-account

# Assume role in product account from management account
export AWS_PROFILE=payments-account

terraform init
terraform plan
terraform apply
```

**Option B: From Management Account (with assume role)**

```bash
cd live/payments-account

# Use cross-account assume role
terraform init
terraform plan -var "assumed_role_arn=arn:aws:iam::987654321098:role/OrganizationAccountAccessRole"
terraform apply
```

#### 5. Verify Product Account Setup

Check the product account AWS console:

```bash
# Set AWS profile to product account
export AWS_PROFILE=payments-account

# Verify Config recorder
aws configservice describe-configuration-recorders

# Verify CUR bucket
aws s3 ls | grep finops-cur

# Verify budgets
aws budgets describe-budgets --account-id 987654321098

# Verify SNS topics
aws sns list-topics
```

### Configuration for Multiple Product Accounts

To manage multiple product accounts efficiently:

```
live/
├── management-account/
│   └── main.tf
├── payments-account/
│   └── main.tf
├── lending-account/
│   └── main.tf
├── platform-account/
│   └── main.tf
└── shared-services-account/
    └── main.tf
```

Each follows the same pattern as `prod-app1-account/main.tf`.

### Cost Allocation Strategy

Product accounts inherit cost allocation from the management account:

1. **Organization-level dimensions** (defined in management account):
   - Application (via cost categories)
   - Business Unit (via OU structure)
   - Environment (via tags)

2. **Product-level tracking** (each product account):
   - Own CUR bucket for detailed analysis
   - Own budgets for cost control
   - Own SNS topics for team alerts
   - Own cost categories for internal allocation

3. **Consolidated reporting** (management account):
   - Organization aggregator shows all product compliance
   - Centralized CUR combines all product costs
   - Single Cost Explorer view with all categories

### Scaling Considerations

As you add more product accounts:

- **Naming Convention:** Use consistent patterns (`<type>-<name>-account`)
- **Tag Strategy:** Sync tags across products via management account
- **Budget Limits:** Adjust per product in their respective `main.tf`
- **SNS Subscriptions:** Each product team gets their own topic
- **Config Rules:** Inherited from organization, extended per product

---

## 

## 90‑Day Rollout Phases

### Day 1–30: Inform (Crawl) 🚶
**Goal:** Establish baseline and governance

**Infrastructure Deployed:**
- Platform admin role and IAM setup (finops-foundation)
- AWS Organization with OUs and SCPs (finops-org)
- AWS Config recorder and compliance rules (finops-config)
- CUR S3 bucket initialization (finops-cur-budgets)
- Cost categories for allocation (finops-cost-categories)

**Product Accounts:** None yet (focus on management account)

**Target Outcome:** ≥50% allocatable spend via tags/accounts

### Day 31–60: Optimize (Walk) 🚶‍♀️
**Goal:** Improve visibility and (organization-wide)
- CUR hourly reports available for analysis
- Account and product budgets with alerts
- Cost categories defined for allocation
- First 2-3 product accounts onboarded

**Product Accounts:** 2-3 pilot products deployed to dedicated accounts
- CUR hourly reports available for analysis
- Account and product budgets with alerts
- Cost categories defined for allocation

**Target Outcome:** ≥70% allo (QuickSight, Tableau, etc.)
- Regular budget reviews and escalations
- Cost category allocations driving charge-backs
- Engineering teams using FinOps metrics in SDLC
- Optimization automation in place (Lambda, Step Functions)
- All product accounts contributing to cost visibility

**Product Accounts:** 5+ products fully operational and tracked
**Infrastructure Mature:**
- Full operational dashboards
- Regular budget reviews and escalations
- Cost category allocations driving charge-backs
- Engineering teams using FinOps metrics
- Optimization automation in place

**Target Outcome:** ≥80–90% allocatable spend with automation

---

## 90‑Day Success Metrics

| Metric | Day 30 (Crawl) | Day 60 (Walk) | Day 90 (Run) |
|--------|---|---|---|
| **Spend Allocation** | ≥50% allocatable | ≥70% allocatable | ≥80–90% allocatable |
| **Forecast Variance** | ±20% MoM | ±15% MoM | ±12% MoM |
| **Optimization Savings** | $5–10K/mo identified | $10–20K/mo realized | Continuous pipeline + automation |
| **Commitment Coverage** | Baseline documented | 50–60% coverage | 60–70% coverage target |
| **Commitment Utilization** | N/A | Tracking started | ≥90% utilization |
| **Engineering Engagement** | 2–3 pilot teams | 5+ teams using dashboards | Org-wide adoption |

---

## Project Status: ✅ Production Ready

This project has been thoroughly reviewed and all critical issues have been remediated:

### Validation Completed
- ✅ All 12 issues identified and fixed
- ✅ All module dependencies verified
- ✅ All variables properly declared
- ✅ All outputs correctly exported
- ✅ All Terraform syntax validated
- ✅ AWS best practices applied
- ✅ Security review completed

### What's Included
- ✅ 5 core infrastructure modules
- ✅ Management account configuration
- ✅ Production-ready Terraform code
- ✅ Comprehensive documentation
- ✅ Deployment guides and checklists
- ✅ Architecture validation reports

See [PROJECT_REVIEW_REPORT.md](PROJECT_REVIEW_REPORT.md) for complete details.

---

## Documentation Index

| Document | Purpose | Best For |
|----------|---------|----------|
| **README.md** (this file) | Overview and quick start | Everyone |
| **PROJECT_REVIEW_REPORT.md** | Remediation & validation | Stakeholders |
| **QUICK_REFERENCE.md** | Deployment & customization | DevOps engineers |
| **REVIEW_DETAILED.md** | Architecture & deep dive | Architects |
| **INDEX.md** | Navigation & reference | All readers |

---

## How to Use This Repository

### For New Teams (Onboarding)

1. **Clone** this repository
2. **Review** [README.md](README.md) and module READMEs
3. **Study** [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for deployment steps
4. **Deploy Management Account:**
   - Customize `live/management-account/main.tf` with your account details
   - Run `terraform init && terraform apply` in `live/management-account`
   - Validate organization, Config, and CUR are operational
5. **Onboard Product Accounts:**
   - Follow steps in [Onboarding Product Accounts](#onboarding-product-accounts)
   - Create `live/<product>/main.tf` for each product using template
   - Deploy to each product account
6. **Create documentation:**
   - `docs/FinOps-Charter.md` (1 page, roles and scope)
   - `docs/RACI.md` (responsibility matrix)
   - `docs/Tagging-Policy.md` (tag requirements)
   - `docs/KPIs.md` (success metrics)
7. **Follow** 90‑day cadence: Inform (Days 1–30), Optimize (Days 31–60), Operate (Days 61–90)

### For Existing FinOps Teams

1. **Review** [PROJECT_REVIEW_REPORT.md](PROJECT_REVIEW_REPORT.md) for validation status
2. **Compare** module structure to your current setup
3. **Adopt** reusable patterns from the modules
4. **Extend** modules with organization-specific configurations
5. **Integrate** with existing BI and automation tools

### For Cloud Architects

1. **Read** [REVIEW_DETAILED.md](REVIEW_DETAILED.md) for complete architecture
2. **Validate** against your organizational standards
3. **Customize** tagging, budget limits, and cost categories
4. **Plan** OU structure for your organization
5. **Design** escalation procedures for budget alerts

---

## Module Variable Reference

### finops-foundation
```hcl
management_region            = "us-east-1"  # Home region
platform_admin_principal_arn = "arn:aws:iam::123456789012:role/OrgAdmin"  # Trusted principal
finops_email                 = "finops@company.com"  # Alert email
default_tags = {                          # Organization-wide tags
  CostCenter  = "FINOPS-GOV"
  Environment = "org-root"
  Owner       = "platform-team"
}
```

### finops-org
```hcl
management_region = "us-east-1"
default_tags      = module.finops_foundation.default_tags
# Optional: Add BU-specific OUs by extending organizations-ou-layout.tf
```

### finops-config
```hcl
management_region = "us-east-1"
default_tags      = module.finops_foundation.default_tags
# Optional: Customize allowed regions in scp-baseline-regions-required-tags.tf
```

### finops-cur-budgets
```hcl
management_region   = "us-east-1"
finops_email        = module.finops_foundation.finops_email
default_tags        = module.finops_foundation.default_tags
product_tag_value   = "loan-origination"  # For product-scoped budgets
# Customize: Budget amounts ($5000 account, $2000 product) in budgets-alerts.tf
```

### finops-cost-categories
```hcl
default_tags = module.finops_foundation.default_tags
# Extend: Add more cost categories and rules in cost-categories-module.tf
```

---

## Customization Guide

### Change Budget Limits

Edit `modules/finops-cur-budgets/budgets-alerts.tf`:
```hcl
resource "aws_budgets_budget" "account_monthly" {
  limit_amount = "5000"  # ← Change this amount
  limit_unit   = "USD"
  # ...
}
```

### Change Allowed Regions

Edit `modules/finops-org/scp-baseline-regions-required-tags.tf`:
```hcl
"aws:RequestedRegion" = [
  "us-east-1",      # ← Add/remove regions
  "us-west-2",
  "eu-west-1"
]
```

### Add OU for Business Unit

Edit `modules/finops-org/organizations-ou-layout.tf`:
```hcl
resource "aws_organizations_organizational_unit" "retail" {
  name      = "Retail"
  parent_id = aws_organizations_organization.this.roots.id
}
```

### Add Cost Category Dimension

Edit `modules/finops-cost-categories/cost-categories-module.tf`:
```hcl
resource "aws_ce_cost_category" "environment" {
  name         = "Environment"
  rule_version = "CostCategoryExpression.v1"

  rule {
    value = "Production"
    rule {
      # Add your dimension mapping logic
    }
  }
  default_value = "Unclassified"
}
```

---

## Troubleshooting

### Common Issues

**Q: "Variable not found" error**  
A: Ensure you've customized `live/management-account/main.tf` with your account ID, role ARN, and email.

**Q: S3 bucket already exists**  
A: S3 bucket names are globally unique. The bucket name includes your account ID to make it unique. If you're re-deploying, you may need to destroy the bucket first or use a new account.

**Q: SNS email confirmation not received**  
A: Check spam folder, or re-subscribe manually in SNS console and check for new email.

**Q: Config rules show non-compliance**  
A: Wait 24 hours for Config to evaluate resources. Ensure resources have required tags before creation.

For more troubleshooting, see [QUICK_REFERENCE.md#troubleshooting](QUICK_REFERENCE.md).

---

## AWS Services Used

| Service | Purpose | Module |
|---------|---------|--------|
| **Organizations** | Multi-account governance | finops-org |
| **IAM** | Access control & roles | finops-foundation, finops-config |
| **Service Control Policies** | Account-level guardrails | finops-org |
| **AWS Config** | Configuration compliance tracking | finops-config |
| **Cost & Usage Report** | Detailed cost data | finops-cur-budgets |
| **Budgets** | Cost alerts and controls | finops-cur-budgets |
| **Cost Explorer** | Cost visibility & categories | finops-cost-categories |
| **SNS** | Alert notifications | finops-cur-budgets |
| **S3** | Data storage (Config, CUR) | finops-config, finops-cur-budgets |

---

## Best Practices Implemented

- ✅ **Least Privilege IAM:** PlatformAdminRole restricted to FinOps operations
- ✅ **Default Tags:** Organization-wide tagging applied consistently
- ✅ **S3 Security:** Bucket versioning, public access blocking, encryption
- ✅ **Modular Design:** Reusable modules with clear dependencies
- ✅ **Version Control:** Terraform version requirements specified
- ✅ **Cost Allocation:** Multiple dimensions for comprehensive chargeback
- ✅ **Compliance Automation:** Config rules enforce governance
- ✅ **Multi-Region Support:** Config aggregator for organization-wide visibility

---

## Support & Resources

### Internal Documentation
- **Repository:** https://github.com/qballscholar/aws-control-tower-finops-blueprint
- **Issues & Discussions:** [GitHub Issues](https://github.com/qballscholar/aws-control-tower-finops-blueprint/issues)

### External Resources
- **FinOps Foundation:** https://finops.org/
- **AWS Organizations:** https://docs.aws.amazon.com/organizations/
- **AWS Config:** https://docs.aws.amazon.com/config/
- **AWS Cost Management:** https://docs.aws.amazon.com/cost-management/
- **Terraform AWS Provider:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs

---

## Acronym Reference

| Acronym | Full Term | Context |
|---------|-----------|---------|
| **BU** | Business Unit | Organizational division for cost allocation |
| **CUR** | Cost & Usage Report | Detailed AWS billing data |
| **EDP** | Enterprise Discount Program | AWS volume discounts (PPA) |
| **IAM** | Identity & Access Management | AWS access control service |
| **KPI** | Key Performance Indicator | Metrics for success measurement |
| **MoM** | Month-over-Month | Comparison metric period |
| **OU** | Organizational Unit | Container for accounts in AWS Organizations |
| **RACI** | Responsible, Accountable, Consulted, Informed | Team role matrix |
| **RI** | Reserved Instance | Discounted EC2 commitment |
| **S3** | Simple Storage Service | AWS object storage |
| **SCP** | Service Control Policy | Organization-level permission guardrail |
| **SP** | Savings Plan | Flexible discount commitment |

---

## License

This project is provided as-is for FinOps implementation. Modify and extend as needed for your organization.

---

## Contributing

To contribute improvements, optimizations, or fixes:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request with detailed description
4. Reference any related issues

---

## Project Status

✅ **Version:** 2.0 (Post-Review & Remediation)  
✅ **Status:** Production Ready  
✅ **Last Updated:** February 4, 2026  
✅ **Terraform Version:** ≥ 1.5.0  
✅ **AWS Provider:** ~> 5.0  

For complete review details, see [PROJECT_REVIEW_REPORT.md](PROJECT_REVIEW_REPORT.md).

---

**Start your FinOps journey today. Deploy this blueprint to establish cloud financial management across your AWS organization.**

Academic Sources and References for Project:

1. FinOps Foundation. **“FinOps: A New Approach to Cloud Financial Management.”**  
   https://www.itsvalue.com/wp-content/uploads/2023/10/FinOps-New-Approach-to-Cloud-Financial-Management.pdf  
   Used for the Inform → Optimize → Operate lifecycle, six FinOps principles, and the distinction between usage and rate optimization that underpins the 90‑day plan and optimization sprints.

2. Amazon Web Services. **“FinOps: Establishing an Operating Model for the Cloud.”**  
   https://pages.awscloud.com/rs/112-TZM-766/images/FinOps-Establishing-an-Operating-Model-for-the-Cloud.pdf  
   Informed the AWS Cloud Financial Management (Plan/Save/Run/See) framework, emphasizing account structure, tagging, CUR, Budgets, Cost Explorer, and QuickSight, all reflected in the Terraform landing zone.

3. FinOps Foundation. **“U.S. Public Sector FinOps Playbook.”**  
   https://www.finops.org/wp-content/uploads/2022/10/FinOps-Foundation_US-Gov-Playbook.pdf  
   Shaped the operating model, RACI, tagging strategy, and governance narrative, including staged adoption (planning, socializing, operating) and emphasis on budgets, contracts, and showback/chargeback.

4. Hystax / FinOps in Practice. **“From FinOps to Proven Cloud Cost Management.”**  
   https://finopsinpractice.org/wp-content/uploads/2021/05/FinOps-ebook-From-FinOps-to-proven-cloud-cost-management.pdf  
   Influenced the cultural and process design by highlighting visibility, continuous optimization, control, collaboration, and the need for ongoing optimization sprints with engineers owning resource lifecycles.




