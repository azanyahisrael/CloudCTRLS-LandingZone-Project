# ADR-0006: Module and root configuration layout

- **Status:** Accepted
- **Date:** 2026-11-18

## Context

From Phase 3, infrastructure is built from reusable modules. The layout decides how code is reused, how state is split, and how much one change can affect.

## Decisions

**1. Reusable modules, deployable roots**

```
modules/
  shared/naming/        names and tags for both clouds (no resources)
  azure/<component>/    Azure building blocks (network, key vault, ...)
  aws/<component>/      AWS building blocks
environments/
  prod/
    azure/<layer>/      e.g. landing-zone, app - each a root with its own state
    aws/<layer>/
bootstrap/
  azure/ aws/           state backends, applied once (Phase 2)
```

- **Modules** contain the logic and are referenced by local path (`source = "../../../../modules/..."`).
- **Roots** under `environments/` only supply inputs and call modules. Each root has its own state key, e.g. `prod/azure/landing-zone.tfstate`.

**2. Roots split by environment, cloud and layer.** An application deploy cannot touch networking or policy, plans stay small, and each cloud keeps independent state ([ADR-0004](0004-terraform-state-per-cloud.md)). Layers share values through outputs.

**3. Production only, dev-ready.** Only `prod` is built to control cost. Environment is an input everywhere, so adding `dev` means a new `environments/dev/` folder with different values, not new code.

**4. One naming module.** The naming convention lives in `modules/shared/naming` and is covered by `terraform test`, so names cannot drift between modules or clouds.

## Alternatives considered

| Option | Why not chosen |
|---|---|
| One root per environment and cloud | Simpler wiring, but every app change plans against the whole landing zone and a mistake can reach anything. |
| dev and prod from the start | Realistic promotion flow, but roughly doubles running cost once compute and databases exist. |
| Modules from versioned Git tags | Useful when modules live in a separate repo; unnecessary overhead while everything is in one repository. |

## Consequences

- Cross-layer values (for example subnet IDs used by the app layer) are passed through outputs, adding some wiring.
- No dev environment to test changes in first; CI checks (Phase 7) and `terraform plan` review are the safety net.
- The bootstrap configurations keep their own inline naming; they are already deployed and renaming would replace the state storage.
