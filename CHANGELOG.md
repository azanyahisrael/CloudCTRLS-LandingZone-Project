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
