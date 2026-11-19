# Phase 3 Lessons Learned

- **Azure's hierarchy decides where rules apply.** Tenant root, management groups, subscriptions, resource groups, resources. Policy, access and budgets attach at a level and flow down; only whole subscriptions move between management groups.
- **Tenant-level objects have no region.** Management groups and subscriptions are folders, not things in a datacenter, so their names stop at the environment.
- **A budget only sees its own scope.** A new subscription needs its own budget, or its spend is invisible.
- **New subscriptions are eventually consistent.** Tags and CLI visibility can lag by minutes; wait and re-check before re-applying, and refresh the CLI with `az account list --refresh`.
- **Moving a resource changes its ID and drops its role assignments.** The move keeps data and names, but Terraform state must be re-imported under the new IDs, locks must be removed first and restored after, and data-plane roles must be granted again.
- **Back up state before surgery.** Downloading both state files first made every later step reversible.
- **SCPs limit, they never grant, and never touch the management account.** That makes the management account the break-glass path, and means guardrails must be tested from a member account.
- **A deny can be tested without creating anything.** A read call in a blocked region, or a destructive call on a resource that does not exist, proves an SCP works because authorization is checked first.
- **Not everything has an API.** Enabling the Identity Center organization instance is console-only, so it is documented step by step and the rest is imported into Terraform.
- **Read every default before clicking Enable.** The default multi-Region Identity Center instance adds a paid KMS key.
- **CLI profiles live on the machine, not in the repo.** Each computer needs its own `aws configure sso`.
