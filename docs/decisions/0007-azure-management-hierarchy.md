# ADR-0007: Azure management group hierarchy and dedicated subscription

- **Status:** Accepted
- **Date:** 2026-11-19

## Context

The only Azure subscription (`Azure-Sub-lab01`) sits under the management group `mg-learning-lab` and also hosts an unrelated project. Azure applies policy, access and budgets at management group and subscription level, and only whole subscriptions can move between management groups. A resource group cannot be filed under a different management group on its own.

## Decisions

**1. A dedicated subscription per environment.** CloudCTRLS prod runs in `sub-cloudctrls-prod`, created by Terraform (subscription alias) on the same billing invoice section as the existing subscription. `prevent_destroy` and the provider's `prevent_cancellation_on_destroy` stop `terraform destroy` from cancelling it.

**2. Its own hierarchy under the tenant root.**

```
Tenant Root Group
├── mg-learning-lab          (unrelated, untouched)
└── mg-cloudctrls            shared guardrails (policy baseline, Step 3.2c)
    └── mg-cloudctrls-prod
        └── sub-cloudctrls-prod
```

Each environment root owns its environment management group and subscription; guardrails common to every environment are assigned once on `mg-cloudctrls` and inherited. `mg-cloudctrls-dev` is added by `environments/dev/azure/landing-zone` when a dev subscription exists.

**3. Names follow the project convention, without region.** Management groups and subscriptions are tenant-level and have no location, so they use `mg-<project>-<env>` and `sub-<project>-<env>`, produced by the naming module and covered by its tests.

**4. Every subscription gets its own budget in code.** A budget only sees its own scope, so `budget-cloudctrls-prod` ($20/month, alerts at actual 50% and 80%, forecast 100%) is created with the subscription and notifies its Owners by role, keeping email addresses out of code.

**Rationale (owner):** CloudCTRLS should not live inside another project's management group and subscription.

## Alternatives considered

| Option | Why not chosen |
|---|---|
| Move `Azure-Sub-lab01` under a CloudCTRLS management group | Brings the unrelated project under CloudCTRLS guardrails and budget. |
| Keep the layout and assign policy to `Azure-Sub-lab01` | CloudCTRLS stays filed under another project; its policy would also hit that project. |
| Full Cloud Adoption Framework hierarchy (platform, connectivity, identity, landing zones) | Designed for many subscriptions; adds empty groups with one subscription per environment. |

## Consequences

- The Terraform state backend still lives in `Azure-Sub-lab01`, and the provider runs in that subscription until the backend moves into `sub-cloudctrls-prod` (Step 3.2b).
- Tearing down the landing zone leaves the subscription in place; cancelling it is a deliberate manual action.
- A future dev environment adds a subscription and `mg-cloudctrls-dev` through a new `environments/dev/` root, with no new code.
