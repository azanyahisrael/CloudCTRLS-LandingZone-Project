# Phase 2 Lessons Learned

- **Terraform describes, it does not fetch.** A `resource` block declares what should exist; the provider (`azurerm`, `aws`) translates it into API calls that create it. Names are built from variables and locals, not looked up.
- **State is Terraform's memory.** It maps code to real resource IDs. It can hold secrets, so it belongs in an encrypted, versioned, locked remote backend, never on a laptop or in Git.
- **The bootstrap chicken-and-egg.** The state backend is created with local state, then `terraform init -migrate-state` moves that state into the storage it just created.
- **Locks are real objects.** Azure locks state with a blob lease; AWS with a `.tflock` file. Knowing that made it possible to test locking directly and to recover a stuck lock.
- **A saved plan is single-use.** It is a snapshot of one moment and remembers the backend it was made with. Always re-plan before the next apply.
- **Azure and AWS organise resources differently.** Azure requires resource groups; AWS resources live directly in an account and region and are grouped by tags and, later, separate accounts.
- **One region per cloud is not enough thinking.** Azure East US and AWS us-east-1 are both in Northern Virginia; real failover needs geographic separation, which led to us-west-2.
- **Budgets alert, they do not stop spending,** and a budget scoped to one resource group cannot see the rest of the subscription.
- **Modules plus tests keep conventions honest.** The naming module is the single source of names and tags, and `terraform test` proves it matches what is actually deployed.
