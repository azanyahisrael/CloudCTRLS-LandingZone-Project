# Project Progress

## Current

**Phase 2, Step 5:** Terraform module structure and shared conventions for workloads.

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

## Blockers

None.

## Open risks

- Long-lived AWS access key for `azx2` is active on another computer. Migrate it to `aws login`, then deactivate the key.
- Leftover Azure resource group `rg-packer-lab` from an earlier project is the likely source of unexplained spend.

## Next

- Phase 2: Terraform foundation (remote state and module structure)
