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
- The empty resource group left in `Azure-Sub-lab01` was confirmed empty and deleted.

## Step 2c: Azure policy baseline

**Status:** Complete, validated 2026-11-19. See [ADR-0008](../decisions/0008-azure-policy-baseline.md).

Five assignments of built-in policies on `mg-cloudctrls`, inherited by every CloudCTRLS environment. Added to [environments/prod/azure/landing-zone](../../environments/prod/azure/landing-zone/main.tf).

| Assignment | Rule | Effect |
|---|---|---|
| `allowed-locations` | Resources only in `eastus` | Deny |
| `allowed-locations-rg` | Resource groups only in `eastus` | Deny |
| `rg-tag-project` | Resource groups must have a `project` tag | Deny |
| `rg-tag-env` | Resource groups must have an `env` tag | Deny |
| `rg-tag-managed_by` | Resource groups must have a `managed_by` tag | Deny |

**Cost:** $0. Built-in Azure Policy on Azure resources is free.

**Validation:**
- `terraform plan`: 5 to add, 0 to change, 0 to destroy; parameters reviewed (`eastus`; one tag name per assignment; enforcement on).
- After apply, `az policy assignment list` on `mg-cloudctrls` returned all five.
- Not yet tested: an attempted deny (resource group outside `eastus`, or without tags). The first resource group created in a later step exercises the tag rules.

## Step 3: Azure central logging

**Status:** Complete, validated 2026-11-19.

One Log Analytics workspace in `sub-cloudctrls-prod` receives the subscription activity log and access logs for the Terraform state storage. Added in [logging.tf](../../environments/prod/azure/landing-zone/logging.tf).

| Resource | Setting |
|---|---|
| `rg-cloudctrls-logging-prod-eastus` | `eastus`, standard tags |
| `log-cloudctrls-logging-prod-eastus` | PerGB2018, 30-day retention, 0.15 GB daily cap |
| Diagnostic setting on the subscription | All 8 activity log categories (Administrative, Security, ServiceHealth, Alert, Recommendation, Policy, Autoscale, ResourceHealth) |
| Diagnostic setting on `stcloudctrlstfstatectrl1` blob service | StorageRead, StorageWrite, StorageDelete |

**Cost:** about $0. Activity log ingestion is free, 30-day retention is included, and the daily cap keeps blob logs inside the 5 GB per month free allowance. Shortcut: once the cap is reached, logs are dropped for the rest of the day; raise or remove it when workloads log here.

**Validation:**
- `terraform plan`: 4 to add, 0 to change, 0 to destroy. After apply, a fresh plan showed no changes.
- `az` confirmed the workspace settings (retention 30, cap 0.15), both diagnostic settings and their categories.
- A query on the workspace returned rows in both `AzureActivity` and `StorageBlobLogs`.
- The logging resource group was created under the Step 2c policies, confirming that a tagged `eastus` resource group is allowed. The deny path is still untested.

## Step 4: AWS Organization, SCPs and IAM Identity Center

**Status:** Complete, validated 2026-11-19. See [ADR-0009](../decisions/0009-aws-organization-and-identity.md).

### 4a: IAM Identity Center (console)

Enabling the organization instance has no API, so this part was done in the management account console:

| Action | Setting |
|---|---|
| Enable IAM Identity Center | Organization instance, primary `us-west-2`, replicated to `us-east-2` (multi-Region, customer-managed KMS key) |
| MFA | Every sign-in; authenticator apps and security keys; registration required at first sign-in |
| User | `cloudctrls-admin` (built-in directory) |
| Permission set | `AdministratorAccess`, 1-hour sessions, assigned on both accounts |
| CLI | `aws configure sso` profiles `cloudctrls-mgmt` and `cloudctrls-prod`, one shared SSO session |

### 4b: Organization structure and SCPs (Terraform)

New root [environments/prod/aws/landing-zone](../../environments/prod/aws/landing-zone/main.tf), state key `prod/aws/landing-zone.tfstate` in the existing S3 bucket.

| Resource | Result |
|---|---|
| `ou-cloudctrls` → `ou-cloudctrls-prod` | Created; workload account moved from the root into `ou-cloudctrls-prod` |
| SCP `region-lock` on `ou-cloudctrls` | Deny outside `us-west-2` (and `us-east-1` since 2026-11-20), global services exempt |
| SCP `protect-security-services` on `ou-cloudctrls` | Deny stopping or deleting CloudTrail, Config, GuardDuty |
| SCP `DenyLeaveAndCloseAccount` on the root | Pre-existing; imported unchanged |
| Permission set, policy attachment, 2 account assignments | Imported from 4a |

Seven existing objects were imported with `terraform import`, using IDs looked up at run time so none are stored in code.

**Cost:** about $2 per month for the Identity Center multi-Region KMS key. Organizations, SCPs and Identity Center are free.

**Validation:**
- `terraform plan`: 6 to add, 3 to change (the account move, plus tags on imported objects), 0 to destroy. After apply, a fresh plan showed no changes.
- `aws organizations` confirmed the OU tree, the account's new parent and the SCPs on `ou-cloudctrls`.
- Denial tests from the workload account as `cloudctrls-admin`:
  - `ec2:DescribeVpcs` in `us-east-1`: denied, "explicit deny in a service control policy" (`region-lock`).
  - The same call in `us-west-2`: allowed.
  - `cloudtrail:StopLogging` on a non-existent trail: denied by `protect-security-services` before the resource lookup.
- The management account could still call `us-east-1`, confirming SCPs do not apply to it.
- `bootstrap/aws` plan using the `cloudctrls-prod` profile: no changes, so the state backend no longer depends on `azx2`.

### 4c: Region lock amended (2026-11-20)

The lock blocked an existing image pipeline in the workload account that uses an AMI in `us-east-1`.

| Action | Result |
|---|---|
| `region-lock` detached temporarily (CLI, management account) | Pipeline access restored; AMI found in `us-east-1` |
| `us-east-1` added to the SCP in Terraform, attachment re-applied | Plan: 1 to add, 1 to change, 0 to destroy |
| AMI copied to `us-west-2` | Same name and tags; 30 GB unencrypted snapshot, about $1.50 per month |

**Validation:** fresh `terraform plan` showed no changes; from the workload account `us-east-1` was allowed and `eu-west-1` returned "explicit deny in a service control policy".

