# Phase 3: Landing Zones

## Step 1: Inventory and cost guardrails

**Status:** Complete, validated 2026-11-19.

Before building shared foundations, the existing state of both clouds was inventoried read-only and budgets were raised for the services Phase 3 introduces.

### Findings

| Cloud | Finding | Impact |
|---|---|---|
| Azure | Subscription sits under management group `mg-learning-lab`, directly below the tenant root | Phase 3 governance must decide where CloudCTRLS policy is scoped |
| Azure | Only policy assignment is the Defender for Cloud default initiative (Microsoft cloud security benchmark, audit only) | No existing guardrails to conflict with |
| Azure | The subscription also hosts a separate project (`rg-packer-lab`) | Out of scope for CloudCTRLS, but its spend counts against the shared subscription budget and subscription-scoped policy reaches it |
| AWS | The CLI account is a member of an existing AWS Organization, not its management account | Organization-level controls (SCPs, IAM Identity Center, organization trail) are managed from the management account; settled in Step 4 |

### Budgets

| Cloud | Before | After |
|---|---|---|
| Azure | $10/month, subscription scope | $10/month (unchanged) |
| AWS | $1/month tripwire | $10/month |

### Phase 3 cost model (planned)

| Cost | Azure | AWS |
|---|---|---|
| Free | Management groups, Azure Policy, Defender for Cloud foundational CSPM, VNets and NSGs, activity log ingestion into Log Analytics | Organizations, SCPs, IAM Identity Center, VPCs and security groups, first CloudTrail management trail |
| Low | Log Analytics ingestion beyond the free allowance | KMS ($1/key/month), AWS Config, GuardDuty and Security Hub after trials |
| Deferred | Azure Firewall, Bastion, NAT Gateway, Defender per-resource plans, Entra ID P1/P2 | NAT Gateway, public IPv4 addresses |

Deferred items cost $30 to $900 per month each and are not required to prove the landing zone design. Each is revisited when a later phase needs it.

### Planned order

| Step | Scope |
|---|---|
| 2a | Azure management group hierarchy and dedicated subscription |
| 2b | Move the Terraform state backend into the new subscription |
| 2c | Azure policy baseline |
| 3 | Azure central logging |
| 4 | AWS account structure, SCPs, IAM Identity Center |
| 5 | AWS CloudTrail, KMS, Config, GuardDuty |
| 6 | Azure hub VNet and AWS VPC, no paid gateways |

**Validation:** Azure management group placement, policy assignments and budget read with the Azure CLI. AWS Organization membership read with the AWS CLI. AWS budget set in the console by the account owner.

## Step 2a: Management group hierarchy and dedicated subscription

**Status:** Complete, validated 2026-11-19. See [ADR-0007](../decisions/0007-azure-management-hierarchy.md).

CloudCTRLS gets its own place in Azure instead of sharing a subscription and management group with another project. Everything is created by the first `environments/` root ([ADR-0006](../decisions/0006-module-and-root-layout.md)): [environments/prod/azure/landing-zone](../../environments/prod/azure/landing-zone/), state key `prod/azure/landing-zone.tfstate`.

| Resource | Value |
|---|---|
| Management group | `mg-cloudctrls`, directly under the Tenant Root Group |
| Management group | `mg-cloudctrls-prod`, under `mg-cloudctrls` |
| Subscription | `sub-cloudctrls-prod`, same billing invoice section as the existing subscription, standard tags |
| Placement | `sub-cloudctrls-prod` associated with `mg-cloudctrls-prod` |
| Budget | `budget-cloudctrls-prod`, $20/month; alerts at actual 50% and 80%, forecast 100%, sent to subscription Owners |

- **Names** come from two new naming module outputs, `management_group` and `subscription` (`mg-`/`sub-<project>-<env>`, no region because these are tenant-level). A fifth test covers them: `Success! 5 passed, 0 failed.`
- **Safety:** the subscription has `prevent_destroy`, and the provider sets `prevent_cancellation_on_destroy`, so no Terraform run can cancel it.
- **Billing scope** is a git-ignored `terraform.tfvars` value marked `sensitive`, so it never appears in plan output or the repository.
- **Cost:** $0. Management groups and an empty subscription are free.

**Validation:**
- `terraform plan` before apply: 5 to add, 0 to change, 0 to destroy; values reviewed from `terraform show -json`.
- `terraform state list`: 5 resources.
- Azure CLI: `mg-cloudctrls-prod` parent is `mg-cloudctrls`, whose parent is the Tenant Root Group; `mg-learning-lab` and `Azure-Sub-lab01` unchanged.
- Owner role on `sub-cloudctrls-prod`; budget present at $20/month with three alerts; all six standard tags present on the subscription.
- Final `terraform plan`: no changes.

## Step 2b: Move the Terraform state backend

**Status:** Complete, validated 2026-11-19.

The state storage account moved from `Azure-Sub-lab01` into `sub-cloudctrls-prod` with Azure's resource move, keeping its name, data and blob versions. Backend blocks needed no change: they address the storage account by name and authenticate with Entra ID.

| # | Action | Why |
|---|---|---|
| 1 | Downloaded both state files to a local backup | Recovery point if the move failed |
| 2 | Registered `Microsoft.Storage` on the new subscription, created an empty `rg-cloudctrls-tfstate-prod-eastus` there | A move needs a registered provider and an existing target resource group |
| 3 | Removed the `CanNotDelete` lock | Locks block moves out of a resource group |
| 4 | `validateMoveResources` dry run, then `az resource move` (164 s) | Confirm the move is allowed before committing to it |
| 5 | Re-created the Storage Blob Data Contributor assignment | Role assignments on a resource are dropped when it changes subscription; without it Terraform cannot read state |
| 6 | `bootstrap/azure`: `terraform state rm` and `terraform import` of the resource group, storage account, container and role assignment under their new IDs | Resource IDs include the subscription, so state still pointed at the old ones |
| 7 | `terraform apply` re-created the lock from code | Restores the delete protection |
| 8 | Both roots' `subscription_id` set to `sub-cloudctrls-prod` | The provider now runs in the CloudCTRLS subscription |

**Validation:**
- Both state blobs listed and `unlocked` after the move; Terraform read and wrote them.
- `bootstrap/azure` plan before step 7: 1 to add (the lock), 0 to change, 0 to destroy; after apply: no changes.
- `environments/prod/azure/landing-zone` plan: no changes.
- `lock-cloudctrls-tfstate-prod-eastus` (`CanNotDelete`) present on the storage account in its new subscription.
