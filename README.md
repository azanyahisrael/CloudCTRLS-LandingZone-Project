# CloudCTRLS

A secure, reusable multi-cloud infrastructure platform that manages Microsoft Azure and AWS as one system, built with Terraform, Packer, Docker, GitHub Actions and unified monitoring.

> **Status: Phases 1 and 2 complete (project foundation, Terraform state backends in both clouds, tested naming module). Phase 3 (landing zones) in progress.** No cloud infrastructure is deployed yet. Everything below marked *Planned* is design intent, not completed work.

## Why I built this

I want to be able to design, deploy, secure, automate, monitor, troubleshoot and operate production-style cloud infrastructure, not just follow tutorials for one service at a time. CloudCTRLS forces the problems real platform teams face: two clouds that must behave like one platform, security controls that are enforced rather than documented, and failover that is tested rather than assumed. Every decision, failure and fix is recorded here so the reasoning is as visible as the result.

## Objectives

- One platform managing Azure (primary) and AWS (secondary) through shared Terraform modules
- Security by default: NIST SP 800-53 Moderate-aligned controls, CIS-hardened images, Zero Trust principles
- Secure CI/CD with automated security gates
- A three-tier containerized application with autoscaling and cross-cloud failover
- Unified monitoring across both clouds
- A read-only AI operations agent (CloudCTRLS Sentinel)

## Architecture (planned)

See [docs/architecture/overview.md](docs/architecture/overview.md).

## Roadmap

| Phase | Scope | Status |
|---|---|---|
| 1 | Planning, repo structure, dev environment, docs | Complete |
| 2 | Terraform foundation and module structure | Complete |
| 3 | Azure + AWS landing zones (governance, identity, networking, logging) | In progress |
| 4 | CIS-hardened golden images (Packer) | Planned |
| 5 | Docker three-tier application | Planned |
| 6 | VM autoscaling and load balancing | Planned |
| 7 | Secure CI/CD and policy enforcement | Planned |
| 8 | Unified monitoring (Grafana / OpenTelemetry) | Planned |
| 9 | Cross-cloud failover and DR testing | Planned |
| 10 | CloudCTRLS Sentinel AI agent | Planned |
| 11 | Security validation, NIST mapping, portfolio demos | Planned |
| 12 | (Optional) AKS / EKS | Planned |

## Documentation

| Folder | Contents |
|---|---|
| [docs/architecture](docs/architecture/) | Diagrams and design explanations |
| [docs/decisions](docs/decisions/) | Architecture Decision Records (why each choice was made) |
| [docs/implementation](docs/implementation/) | How each component was built, with validation evidence |
| [docs/security](docs/security/) | NIST control mappings, CIS decisions, security testing |
| [docs/troubleshooting](docs/troubleshooting/) | Problems hit, diagnostics, resolutions |
| [docs/lessons-learned](docs/lessons-learned/) | Concepts and skills learned |

Progress: [PROJECT_PROGRESS.md](PROJECT_PROGRESS.md) · Changes: [CHANGELOG.md](CHANGELOG.md)

## Security note

This repository never contains credentials, Terraform state, or real variable values. See [.gitignore](.gitignore) for what is excluded. Screenshots used as evidence are cropped to remove account IDs, subscription IDs and email addresses.
