# ADR-0003: Terraform for Infrastructure as Code

- **Status:** Accepted
- **Date:** 2026-11-18

## Context

Infrastructure in both Azure and AWS must be defined as code, reviewed before it changes, and protected from conflicting or unsafe changes.

## Decision

Use **Terraform** for all infrastructure in both clouds.

## Reasons

- **One tool, one workflow for both clouds.** The same language, module structure and pipeline manage Azure and AWS, which is what makes CloudCTRLS one platform instead of two projects.
- **Changes are previewed before they happen.** `terraform plan` compares the code, the state file and the real infrastructure, then shows every change and any drift (manual changes made outside Terraform) before anything is applied.
- **State locking prevents conflicting changes.** While one run is applying, a second run cannot change the same infrastructure and corrupt the state.
- **Fails safely in CI.** Combined with GitHub Actions and branch protection (Phase 7), a change that fails `validate`, `plan` or a security scan cannot be merged or deployed.

## Alternatives considered

| Option | Why not chosen |
|---|---|
| Bicep | Azure-only. Has a `what-if` preview but no state file or locking, and cannot manage AWS. |
| CloudFormation | AWS-only. |
| Pulumi | Multi-cloud using general-purpose languages. Smaller ecosystem for this kind of work and less common in infrastructure job postings. |
| OpenTofu | Open-source fork of Terraform with nearly identical syntax. A valid alternative; Terraform chosen for its wider industry adoption. |

## Consequences

- **The state file is sensitive.** It can contain secrets in plain text, so it must live in an encrypted remote backend with restricted access and locking, and is never committed (already enforced by `.gitignore`). The backend choice is the first Phase 2 decision.
- **Licensing:** Terraform uses the Business Source License since 2023. Personal and internal use is unaffected.
- **Cost:** the Terraform CLI is free. Remote state storage costs cents per month.

## Validation

Planned for Phase 2: prove that a second concurrent `plan`/`apply` is blocked by the state lock, and that a manual change in the portal shows up as drift in `terraform plan`.
