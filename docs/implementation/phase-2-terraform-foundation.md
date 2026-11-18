# Phase 2: Terraform Foundation

## Step 1: Remote state design

**Status:** Decided 2026-11-18. Each cloud stores its own Terraform state (Azure Storage for Azure, S3 for AWS) so neither cloud is a single point of failure for managing the other. See [ADR-0004](../decisions/0004-terraform-state-per-cloud.md).

## Step 2: Account safety before billable resources

**Status:** Complete, validated 2026-11-18.

Done before creating anything that costs money. Budgets alert on spend; they do not stop it.

### Azure

| Setting | Value |
|---|---|
| Budget scope | Subscription (`Azure-Sub-lab01`), so every resource group is covered |
| Amount | $10 per month |
| Alerts | Actual 50% ($5), Actual 80% ($8), Forecasted 100% ($10) |
| MFA | Enforced by Azure for portal sign-in |

An earlier budget scoped to a single resource group was deleted. A resource-group budget only sees costs inside that group, so resources Terraform creates elsewhere would never trigger it.

### AWS

| Setting | Value |
|---|---|
| Budget | `cloudctrls-monthly-budget`, monthly cost template, whole account |
| Amount | $1 per month, a tripwire while AWS has no workloads |
| Alerts | Template defaults: Actual 85%, Actual 100%, Forecasted 100% |
| Root user MFA | Enabled |

The $1 AWS budget will be raised deliberately before Phase 3 adds KMS, CloudTrail and AWS Config. AWS budget data can lag by up to a day, so alerts are not real-time.

**Validation:** budget settings and alert conditions verified in each console. Screenshots kept privately; they contain subscription IDs and email addresses.

## Step 3: CLI access without long-lived keys

**Status:** Complete, validated 2026-11-18.

| Cloud | Identity | Sign-in | Default region |
|---|---|---|---|
| Azure | CloudCTRLS tenant administrator | `az login` (browser, token expires) | `eastus` |
| AWS | IAM user `azx2` with MFA, AdministratorAccess | `aws login` (browser, short-lived credentials) | `us-west-2` |

Regions are recorded in [ADR-0005](../decisions/0005-regions.md). The AWS root user is used only for billing. IAM Identity Center replaces the IAM user in Phase 3, when AWS Organizations is set up.

**Validation**

```
az account show                 -> subscription Azure-Sub-lab01, tenant CloudCTRLS
aws sts get-caller-identity     -> arn:aws:iam::<account>:user/azx2 (not root)
aws iam list-mfa-devices        -> 1 device
~/.aws/credentials              -> does not exist (no stored keys)
AWS_ACCESS_KEY_ID               -> not set in any scope
```

**Known risk (open):** `azx2` still has an active long-lived access key, created before this project and used on another computer. Plan: switch that machine to `aws login`, then deactivate the key, then delete it once nothing depends on it.

## Step 4a: Azure state backend

**Status:** Complete, validated 2026-11-18. Code: [bootstrap/azure](../../bootstrap/azure/).

| Resource | Name | Key settings |
|---|---|---|
| Resource group | `rg-cloudctrls-tfstate-prod-eastus` | Dedicated to state, separate lifecycle from workloads |
| Storage account | `stcloudctrlstfstatectrl1` | ZRS, TLS 1.2, HTTPS only, no public blob access, shared keys disabled (Entra ID only), infrastructure encryption |
| Blob protection | | Versioning, 30-day blob and container soft delete |
| Role assignment | Storage Blob Data Contributor | Grants the Terraform identity data access, since keys are disabled |
| Container | `tfstate` | Private |
| Management lock | `lock-cloudctrls-tfstate-prod-eastus` | `CanNotDelete`, blocks accidental deletion including `terraform destroy` |

**Naming convention** (Microsoft Cloud Adoption Framework style): `<type>-<project>-<purpose>-<env>-<region>`, for example `rg-cloudctrls-tfstate-prod-eastus`. Storage accounts allow no hyphens, so they use `st<project><purpose><suffix>`, where the suffix makes the name globally unique.

**Bootstrap pattern (chicken-and-egg):** the first `apply` ran with local state. The `backend "azurerm"` block was then enabled and `terraform init -migrate-state` moved the state into the storage account it had just created (key `bootstrap/azure.tfstate`). The local state files were deleted.

**Validation**

```
terraform plan -out tfplan          -> Plan: 5 to add, 0 to change, 0 to destroy (reviewed before apply)
terraform apply tfplan              -> 5 resources created
terraform init -migrate-state       -> state copied to the azurerm backend
az storage blob list ... tfstate    -> bootstrap/azure.tfstate (18,541 bytes)
terraform plan                      -> No changes (state read from Azure)
Lock test: lease acquired on the state blob for 60 s, then terraform plan
                                    -> Error acquiring the state lock: state blob is already locked
```

**Known limitation:** the storage account accepts connections from the internet (Entra ID authentication still required) so the laptop and GitHub-hosted runners can reach it. Network restriction is planned for Phase 3 or 7.
