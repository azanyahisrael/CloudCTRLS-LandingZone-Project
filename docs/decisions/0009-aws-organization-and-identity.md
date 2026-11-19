# ADR-0009: AWS Organization structure, SCPs and IAM Identity Center

- **Status:** Accepted
- **Date:** 2026-11-19

## Context

The CloudCTRLS workload account was a member of an existing AWS Organization sitting directly under the root, and the CLI used the IAM user `azx2` with a long-lived access key. The Organization already had SCPs enabled and one customer SCP denying `LeaveOrganization` and `CloseAccount`. Azure guardrails sit on `mg-cloudctrls` ([ADR-0008](0008-azure-policy-baseline.md)); AWS needs the equivalent.

## Decisions

**1. OUs mirror Azure.** `ou-cloudctrls` under the root, `ou-cloudctrls-prod` under it holding the workload account. A dev OU can be added later. Names come from the naming module (`ou-<project>-<env>`).

**2. IAM Identity Center with its built-in directory replaces IAM users for human access.** Organization instance in the management account, primary Region `us-west-2`. One user, `cloudctrls-admin`, MFA required at every sign-in, `AdministratorAccess` (1-hour sessions) on both accounts. Rationale (owner): short-lived credentials instead of long-lived access keys.

**3. Multi-Region Identity Center instance, replicated to US East (Ohio).** Chosen by the owner over a single-Region instance. Ohio is inland and away from the East Coast, consistent with [ADR-0005](0005-regions.md). It requires a customer-managed multi-Region KMS key (about $2 per month).

**4. SCPs on `ou-cloudctrls`:**
- `region-lock`: deny everything outside `us-west-2`, with global services (IAM, Organizations, STS, billing, Route 53, CloudFront and others) exempt.
- `protect-security-services`: deny stopping or deleting CloudTrail, Config and GuardDuty. Creating and changing them stays allowed.
- The existing `DenyLeaveAndCloseAccount` stays on the root and is now managed in Terraform.

**5. One state bucket.** The landing zone root keeps its state in the existing bucket in the workload account (S3 buckets cannot move between accounts). Its backend uses the `cloudctrls-prod` profile while the provider uses `cloudctrls-mgmt`.

## Alternatives considered

| Option | Why not chosen |
|---|---|
| Keep IAM user `azx2` | Long-lived access keys; one identity per account. |
| Entra ID as the Identity Center source | One identity across both clouds, but more setup and possible licensing; can be switched later (resets users and assignments). |
| Single-Region Identity Center | No KMS cost and no second Region; the owner chose Multi-Region. |
| SCP denying the root user of member accounts | Not chosen by the owner. |
| Second state bucket in the management account | Duplicates the backend for one root. |

## Consequences

- SCPs never apply to the management account, so it is the break-glass path: detach an SCP from there if it blocks recovery.
- Deleting CloudTrail, Config or GuardDuty in member accounts requires detaching `protect-security-services` first.
- Enabling the Identity Center organization instance, its MFA settings and the user were done in the console (no API for enabling); the permission set and assignments were imported into Terraform.
- Every machine used for AWS work needs the `cloudctrls-mgmt` and `cloudctrls-prod` profiles (`aws configure sso`).
