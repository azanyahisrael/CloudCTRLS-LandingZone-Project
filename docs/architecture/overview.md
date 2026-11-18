# Architecture Overview

> **Status: Planned.** Nothing in this diagram is deployed yet. Each component moves to *implemented* only after it is validated.

```
                    GitHub (CloudCTRLS repo)
          Terraform modules | Packer | Actions + security gates
                              |
             OIDC (no stored cloud keys)
              +---------------+---------------+
              |                               |
        AZURE (primary)                  AWS (secondary)
   Mgmt groups, Policy, Defender     Organizations, SCPs, Security Hub
   Hub VNet -> spoke VNets            VPC (+ Transit Gateway later)
   App Gateway/WAF -> VMSS (Docker)   ALB/WAF -> Auto Scaling (Docker)
   Private managed database           Private managed database
              |                               |
              +------ health-based DNS -------+   (failover to AWS)
                              |
          Unified telemetry (OpenTelemetry/Alloy -> Grafana stack)
                              |
              CloudCTRLS Sentinel (read-only AI analyst)
```

## Design principles

- **One platform, two providers.** Shared Terraform modules, pipelines, images and telemetry, not two separate projects.
- **Bootstrap is separate from workloads.** One-time setup (state backends, OIDC trust, accounts) lives apart from reusable workload deployments.
- **Security is the default.** Insecure configurations are blocked by pipeline gates, not just discouraged.
- **Consistent labels everywhere:** `cloud`, `env`, `app`, `region`, so monitoring and cost can be filtered the same way in both clouds.
- **Reuse through inputs.** New environments and applications are added by changing configuration, not copying code.
