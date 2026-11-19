# ADR-0008: Azure policy baseline

- **Status:** Accepted
- **Date:** 2026-11-19

## Context

`mg-cloudctrls` ([ADR-0007](0007-azure-management-hierarchy.md)) is where guardrails common to every CloudCTRLS environment belong. Defender for Cloud's default initiative already audits storage, TLS and encryption settings, but nothing stops resources being created in the wrong region or without the tags the naming module defines.

## Decisions

**1. Built-in definitions only, assigned on `mg-cloudctrls`.** Every environment management group and subscription inherits them. Definitions are looked up by display name, not hard-coded IDs.

**2. Region: `eastus` only, enforced (Deny).** "Allowed locations" and "Allowed locations for resource groups" use the same `location` variable as the rest of the code ([ADR-0005](0005-regions.md)). Global resources are exempt by definition. Failover lives in AWS, not a second Azure region.

**3. Tags on resource groups: `project`, `env`, `managed_by`, enforced (Deny).** One "Require a tag on resource groups" assignment per tag. Chosen by the owner over report-only.

## Alternatives considered

| Option | Why not chosen |
|---|---|
| Report-only tags (enforcement mode `DoNotEnforce`) | Shows non-compliance without blocking; the owner chose enforcement. |
| Require tags on every resource | Breaks child and Azure-created resources that cannot carry tags at creation. |
| Assign at subscription scope | Would need repeating for every future subscription; management group scope is inherited. |

## Consequences

- Resource groups Azure creates on its own (for example `NetworkWatcherRG`) are denied in CloudCTRLS subscriptions, so those resources are created by Terraform with tags (Network Watcher in the networking step).
- Manually created resource groups must carry the three tags, with `managed_by` set to something other than `terraform` where appropriate.
- Assignments reach only `mg-cloudctrls`; other management groups in the tenant are unaffected.
