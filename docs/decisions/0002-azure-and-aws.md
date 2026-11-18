# ADR-0002: Azure as primary cloud, AWS as secondary

- **Status:** Accepted
- **Date:** 2026-11-18

## Context

CloudCTRLS must run one application platform across more than one cloud provider, with automatic failover so the business keeps running if one provider has an outage.

## Decision

Use **Microsoft Azure as the primary** environment and **AWS as the secondary** (failover) environment.

## Reasons

- **They are the two largest cloud platforms**, so they are what most businesses run on and what most cloud roles require.
- **Business continuity across providers.** If one provider has a regional or service outage, traffic fails over to the other. A single-cloud design cannot survive a provider-level failure.

## Alternatives considered

| Option | Why not chosen |
|---|---|
| Single cloud with multi-region failover | Cheaper and simpler, but does not protect against a provider-wide failure and does not build skills on a second platform. |
| Google Cloud as one of the two | Smaller market share than Azure and AWS, so less relevant to the target job market. |

## Consequences

- **Higher complexity:** two identity systems, two network models and two sets of security services must be kept consistent. Shared Terraform modules, naming, tagging and telemetry exist to manage this.
- **Data consistency is the hardest problem.** Cross-cloud failover needs a database replication strategy with defined RTO and RPO (Phase 9).
- **Cost:** running a standby environment in a second cloud adds cost. The AWS side will be kept minimal until failover testing.
