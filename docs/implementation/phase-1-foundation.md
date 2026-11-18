# Phase 1: Project Foundation

## Step 1: Development environment

**Status:** Complete, validated 2026-11-18.

| Tool | Version | Purpose |
|---|---|---|
| Git | 2.56.1 | Version control |
| Terraform | 1.17.1 | Infrastructure as Code |
| Packer | 1.16.2 | Golden image builds |
| Azure CLI | 2.93.0 | Azure authentication and management |
| AWS CLI | 2.41.0 | AWS authentication and management |
| Docker | 29.9.2 | Containers |
| Python | 3.15.2 | Sentinel agent (Phase 10) |
| VS Code | 1.146.0 | Editor |

The GitHub CLI was deliberately not installed. GitHub tasks are done in the github.com web interface.

**Git configuration**
- Commit identity uses the GitHub noreply address, with email privacy enabled on GitHub, so no personal email appears in public commit history.
- Default branch is `main`, matching GitHub.

**Validation:** each tool's `--version` output was checked after a terminal restart. `git config --list --show-origin` confirmed the identity is stored in the global config file and the email matches the `users.noreply.github.com` format.

**Note:** Python 3.15 is a new major version. If a Phase 10 dependency lacks support, Python 3.14 will be installed alongside it.

## Step 2: Repository safety files

**Status:** Complete, validated 2026-11-18.

- `git init` created the repository on branch `main`.
- `.gitignore` excludes Terraform state, plans and `*.tfvars`, Packer variable files, `.env` files, private keys and certificates, Python caches and `.vscode/`. `.terraform.lock.hcl` is intentionally committed to pin provider versions.
- `.gitattributes` stores text with LF endings, keeps `.bat`/`.cmd` as CRLF, and marks images and archives as binary.

**Validation**

```
git check-ignore -v --no-index terraform.tfstate .env prod.tfvars key.pem
  -> all four matched an ignore rule
git check-ignore -v --no-index .env.example .terraform.lock.hcl
  -> .env.example matched the !.env.example exception, lock file not ignored
git check-attr eol -- test.sh test.ps1 test.bat
  -> lf, lf, crlf
```

Decisions made in this step are recorded in [ADR-0001](../decisions/0001-repository-conventions.md). Problems hit are in the [Phase 1 troubleshooting log](../troubleshooting/phase-1-setup.md).

## Step 3: Documentation structure

**Status:** Complete, 2026-11-18.

Created the `docs/` folders, README, PROJECT_PROGRESS and CHANGELOG. Code folders (`modules/`, `bootstrap/`, `app/` and so on) are created in the phase that needs them, so the repository never shows structure for work that does not exist yet.

## Step 5: GitHub repository and branch protection

**Status:** Complete, validated 2026-11-18.

- Published as the public repository `CloudCTRLS-LandingZone-Project`, default branch `main`. The project itself is still named CloudCTRLS.
- The GitHub repository was created empty so the local history pushed without conflicts. Authentication used Git Credential Manager's browser sign-in, so no token is stored in the repository.
- A branch ruleset on `main` restricts deletion and blocks force pushes, so published history cannot be rewritten. Pull request and status-check requirements will be added in Phase 7, once CI checks exist.

**Validation**

```
git log --oneline origin/main         -> 25befd8, matches local main
GET /repos/.../branches/main          -> "protected": true
GET /repos/.../rules/branches/main    -> rules: deletion, non_fast_forward
```

**Issue hit:** the ruleset was created but not enforced until **Enforcement status** was set to **Active**, because GitHub defaults new rulesets to Disabled.
