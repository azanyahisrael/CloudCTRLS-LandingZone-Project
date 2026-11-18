# ADR-0004: Terraform remote state stored per cloud

- **Status:** Accepted (implementation in Phase 2)
- **Date:** 2026-11-18

## Context

Terraform state must be stored remotely so it is encrypted, versioned, locked and reachable from GitHub Actions. CloudCTRLS spans two clouds, so the question is where each cloud's state lives.

## Decision

Each cloud stores its own state:

- **Azure** state in an **Azure Storage** blob container (locking via blob lease).
- **AWS** state in an **S3** bucket (locking via S3 native lock file, `use_lockfile`).

## Reason

Business continuity ([ADR-0002](0002-azure-and-aws.md)). If one cloud has an outage, Terraform must still be able to manage the other cloud, which is exactly when failover changes are needed. Keeping each cloud's state in that cloud means neither provider is a single point of failure for managing the other.

## Alternatives considered

| Option | Why not chosen |
|---|---|
| All state in Azure Storage | One backend, but an Azure outage would block Terraform from managing AWS during failover. |
| HCP Terraform | Provider-neutral, but places the most sensitive file with a third-party SaaS and adds another identity system and dependency. |
| Local state | No locking, no encryption, single copy, unreachable from CI. |

## Consequences

- Two backends must be bootstrapped, secured and documented.
- The backend storage is created before Terraform can use it (bootstrap), so it lives in `bootstrap/`, separate from workloads.
- State can contain secrets: both backends must be private, encrypted, versioned, and restricted to the identities that run Terraform.
- **Cost:** under $1/month per cloud for state storage.

## Validation

Planned: confirm encryption and versioning on both backends, and prove a second concurrent run is blocked by the lock.
