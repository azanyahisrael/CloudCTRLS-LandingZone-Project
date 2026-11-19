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
| 2 | Azure management group and policy baseline |
| 3 | Azure central logging |
| 4 | AWS account structure, SCPs, IAM Identity Center |
| 5 | AWS CloudTrail, KMS, Config, GuardDuty |
| 6 | Azure hub VNet and AWS VPC, no paid gateways |

**Validation:** Azure management group placement, policy assignments and budget read with the Azure CLI. AWS Organization membership read with the AWS CLI. AWS budget set in the console by the account owner.
