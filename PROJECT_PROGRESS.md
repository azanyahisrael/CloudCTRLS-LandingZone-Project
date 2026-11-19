# Project Progress

## Current

**Phase 3 in progress** (Azure and AWS landing zones). Next: Step 3.2c, Azure policy baseline on `mg-cloudctrls`.

## Completed

| Step | Task | Validated | Evidence |
|---|---|---|---|
| 1.1 | Development environment ready | 2026-11-18 | [Phase 1 implementation](docs/implementation/phase-1-foundation.md#step-1-development-environment) |
| 1.2 | Git repository with `.gitignore` and `.gitattributes` | 2026-11-18 | [Phase 1 implementation](docs/implementation/phase-1-foundation.md#step-2-repository-safety-files) |
| 1.3 | Documentation structure, README, changelog | 2026-11-18 | First commit |
| 1.4 | First ADR, troubleshooting log, lessons learned, NIST mapping | 2026-11-18 | [ADR-0001](docs/decisions/0001-repository-conventions.md) |
| 1.5 | Public GitHub repository, `main` protected | 2026-11-18 | [Phase 1 implementation](docs/implementation/phase-1-foundation.md#step-5-github-repository-and-branch-protection) |
| 2.1 | Remote state design: state per cloud | 2026-11-18 | [ADR-0004](docs/decisions/0004-terraform-state-per-cloud.md) |
| 2.2 | Budget alerts and MFA in Azure and AWS | 2026-11-18 | [Phase 2 implementation](docs/implementation/phase-2-terraform-foundation.md#step-2-account-safety-before-billable-resources) |
| 2.3 | CLI access without stored keys; regions decided | 2026-11-18 | [Phase 2 implementation](docs/implementation/phase-2-terraform-foundation.md#step-3-cli-access-without-long-lived-keys), [ADR-0005](docs/decisions/0005-regions.md) |
| 2.4a | Azure state backend, state migrated, lock tested | 2026-11-18 | [Phase 2 implementation](docs/implementation/phase-2-terraform-foundation.md#step-4a-azure-state-backend) |
| 2.4b | AWS state backend, state migrated, lock tested | 2026-11-18 | [Phase 2 implementation](docs/implementation/phase-2-terraform-foundation.md#step-4b-aws-state-backend) |
| 2.5 | Module layout and tested naming module | 2026-11-18 | [Phase 2 implementation](docs/implementation/phase-2-terraform-foundation.md#step-5-module-structure-and-naming-module), [ADR-0006](docs/decisions/0006-module-and-root-layout.md) |
| 3.1 | Cloud inventory, Phase 3 cost model, AWS budget raised to $10 | 2026-11-19 | [Phase 3 implementation](docs/implementation/phase-3-landing-zones.md#step-1-inventory-and-cost-guardrails) |
| 3.2a | Management group hierarchy, dedicated subscription `sub-cloudctrls-prod`, $20 budget | 2026-11-19 | [Phase 3 implementation](docs/implementation/phase-3-landing-zones.md#step-2a-management-group-hierarchy-and-dedicated-subscription), [ADR-0007](docs/decisions/0007-azure-management-hierarchy.md) |
| 3.2b | Terraform state backend moved into `sub-cloudctrls-prod`, state re-imported, lock restored | 2026-11-19 | [Phase 3 implementation](docs/implementation/phase-3-landing-zones.md#step-2b-move-the-terraform-state-backend) |

## Blockers

None.

## Open risks

- Long-lived AWS access key for `azx2` is active on another computer. Migrate it to `aws login`, then deactivate the key.
- The Azure subscription is shared with a separate project. Its spend counts against the same $10 budget, and subscription-scoped policy reaches it.
- The CLI's AWS account is a member of an existing Organization. Ownership of the management account must be confirmed before Step 3.4.

## Next

- Step 3.2c: Azure policy baseline on `mg-cloudctrls`.
