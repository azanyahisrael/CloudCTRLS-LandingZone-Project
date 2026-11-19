# Phase 3 Lessons Learned

- **Azure's hierarchy decides where rules apply.** Tenant root, management groups, subscriptions, resource groups, resources. Policy, access and budgets attach at a level and flow down; only whole subscriptions move between management groups.
- **Tenant-level objects have no region.** Management groups and subscriptions are folders, not things in a datacenter, so their names stop at the environment.
- **A budget only sees its own scope.** A new subscription needs its own budget, or its spend is invisible.
- **New subscriptions are eventually consistent.** Tags and CLI visibility can lag by minutes; wait and re-check before re-applying, and refresh the CLI with `az account list --refresh`.
- **Moving a resource changes its ID and drops its role assignments.** The move keeps data and names, but Terraform state must be re-imported under the new IDs, locks must be removed first and restored after, and data-plane roles must be granted again.
- **Back up state before surgery.** Downloading both state files first made every later step reversible.
