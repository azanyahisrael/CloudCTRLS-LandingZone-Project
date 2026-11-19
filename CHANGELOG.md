# Changelog

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `.gitignore` excluding Terraform state, plan and variable files, Packer variable files, keys and secrets
- `.gitattributes` normalizing line endings (LF by default, CRLF for `.bat` and `.cmd`)
- README, PROJECT_PROGRESS and documentation structure
- Planned architecture overview
- ADR-0001: repository conventions
- Phase 1 implementation evidence, troubleshooting log and lessons learned
- Initial NIST SP 800-53 control mapping
- Public GitHub repository with a branch ruleset protecting `main` from deletion and force pushes
- ADR-0002: Azure as primary cloud, AWS as secondary
- ADR-0003: Terraform for Infrastructure as Code
- ADR-0004: Terraform remote state stored per cloud
- Budget alerts in Azure (subscription scope) and AWS (account scope); MFA on privileged accounts
- ADR-0005: Azure East US primary, AWS us-west-2 secondary
- CLI access for both clouds using short-lived browser sign-in, no stored access keys
- `bootstrap/azure`: Terraform state backend in Azure Storage (Entra ID auth, versioning, delete lock); state migrated and locking verified
- `bootstrap/aws`: Terraform state backend in S3 (public access blocked, ACLs disabled, TLS-only policy, versioning, native lock file); state migrated and locking verified
- ADR-0006: module and root configuration layout (per environment, cloud and layer; prod only, dev-ready)
- `modules/shared/naming`: naming and tagging module for both clouds, covered by `terraform test` (4 tests)
- Phase 3 inventory of both clouds and landing zone cost model; AWS budget raised from $1 to $10
- ADR-0007: Azure management group hierarchy and dedicated subscription
- `environments/prod/azure/landing-zone`: management groups `mg-cloudctrls` and `mg-cloudctrls-prod`, subscription `sub-cloudctrls-prod` with a $20 budget, all in Terraform
- Naming module outputs for management groups and subscriptions (5 tests)
