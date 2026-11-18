# ADR-0005: Regions, Azure East US primary, AWS us-west-2 secondary

- **Status:** Accepted
- **Date:** 2026-11-18

## Context

Cross-cloud failover ([ADR-0002](0002-azure-and-aws.md)) must survive a regional disaster, not only a provider outage. Azure's primary region was already East US (`eastus`, Northern Virginia).

## Decision

| Cloud | Role | Region |
|---|---|---|
| Azure | Primary | East US (`eastus`), Northern Virginia |
| AWS | Secondary (failover) | US West, Oregon (`us-west-2`) |

`us-west-2` is also the AWS home region for the Terraform state bucket and, from Phase 3, IAM Identity Center.

## Reasons

- **Survives an East Coast-wide event.** A hurricane or large grid failure could affect both Virginia and Ohio. Oregon is on the opposite coast.
- **NIST alignment.** CP-6(1) and CP-7(1) require alternate storage and processing sites separated from the primary to reduce susceptibility to the same threats.
- **Replication lag is acceptable.** Cross-cloud database replication is asynchronous regardless of distance, so the extra 60 to 70 ms adds seconds of lag at most, not a design limitation.
- **Capacity and cost.** Four availability zones, low pricing, early access to new services.

## Alternatives considered

| Option | Why not chosen |
|---|---|
| `us-east-1` (N. Virginia) | Same metro as Azure East US: no geographic diversity. Historically the most outage-prone AWS region. |
| `us-east-2` (Ohio) | Initially chosen for the lowest latency, then revised: it does not protect against an East Coast-wide event. |
| `us-west-1` (N. California) | West Coast, but only two availability zones for most accounts and one of the most expensive US regions. |

## Consequences

- East Coast users see roughly 60 to 70 ms more latency while running on AWS after a failover.
- A few AWS features are pinned to `us-east-1` regardless of home region (CloudFront TLS certificates, billing metrics). These are handled individually when needed.
- Azure `eastus` and AWS `us-west-2` are the default region inputs for all Terraform configurations.
