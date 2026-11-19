# Troubleshooting Log (Phases 1 to 3)

## 1. Git identity did not save

- **Symptom:** after running `git config --global user.name ...`, `git config --global --list` failed with `unable to read config file 'C:/Users/XLOUBS/.gitconfig': No such file or directory`.
- **Diagnosis:** `git config --list --show-origin` showed only the system-wide config (`C:/Program Files/Git/etc/gitconfig`). No user-level config existed, so the commands had not run in this machine's terminal.
- **Resolution:** re-ran the commands in the VS Code terminal for this project. `--show-origin` then showed `user.name` coming from the global config file.
- **Lesson:** `--show-origin` shows *where* each setting comes from, which separates "not set" from "set somewhere else".

## 2. `.gitattributes` had no effect

- **Symptom:** line-ending rules were written but not applied.
- **Diagnosis:** the file was saved as `.gitattribute` (no `s`). Git only reads the exact filename and gives no warning for a misnamed one.
- **Resolution:** renamed it to `.gitattributes`, then confirmed with `git check-attr eol -- test.sh test.ps1 test.bat`.
- **Lesson:** verify the behaviour a config file should produce, not just that the file exists.

## 3. Edits did not appear on disk

- **Symptom:** after editing `.gitignore` and `.gitattributes`, the files on disk were unchanged.
- **Diagnosis:** the edits were unsaved in VS Code (white dot on the editor tab).
- **Resolution:** saved the files. Auto Save (File > Auto Save) prevents this.

## 4. Branch protection not enforced

- **Symptom:** after creating a ruleset for `main`, the GitHub API still reported `"protected": false` and no active rules.
- **Diagnosis:** new rulesets default to **Enforcement status: Disabled**. A disabled ruleset exists but enforces nothing.
- **Resolution:** set Enforcement status to Active with `main` as the target. The API then returned `"protected": true` with `deletion` and `non_fast_forward` rules.
- **Lesson:** another case of verifying the effect, not the configuration screen.

## 5. AWS CLI not found after installing it (Phase 2)

- **Symptom:** `aws login` returned `The term 'aws' is not recognized`.
- **Diagnosis:** `aws.exe` existed and its folder was in the system PATH. VS Code had been open during the install, and its terminals inherit the PATH VS Code started with, even new terminal tabs.
- **Resolution:** closed every VS Code window and reopened it.

## 6. State lock test showed no lock (Phase 2)

- **Symptom:** with `terraform console` open in one terminal, `terraform plan` in another ran normally instead of failing on the lock.
- **Diagnosis:** checking the state blob directly (`az storage blob show ... --query properties.lease`) showed `unlocked` while the console was open. `terraform console` reads state without holding the lock, so it was the wrong tool for the test.
- **Resolution:** the azurerm backend locks by placing a lease on the state blob, so the test acquired that lease directly (`az storage blob lease acquire --lease-duration 60`). `terraform plan` then failed with `Error acquiring the state lock`, and the lease expired on its own.
- **Lesson:** test a mechanism at the level it actually works at. Knowing that the Azure lock *is* a blob lease made a reliable test possible.

## 7. State locked indefinitely after acquiring a lease in the portal (Phase 2)

- **Symptom:** a lease was acquired on `bootstrap/azure.tfstate` from the portal's storage browser.
- **Diagnosis:** `az storage blob show ... --query properties.lease` showed `duration: infinite, status: locked`. Portal leases default to infinite, so every Terraform run on that state would fail until the lease was removed.
- **Resolution:** broke the lease (portal **Break lease**, or `az storage blob lease break`). Status returned to `unlocked`.
- **Recovery procedure for a stuck lock:** this is the same situation as a pipeline crashing mid-apply. Use `terraform force-unlock <LOCK_ID>` (ID shown in the lock error), or break the blob lease (Azure) / delete the `.tflock` object (AWS). Only do this when certain no run is active.

## 8. `BucketAlreadyOwnedByYou` when re-applying a saved plan (Phase 2)

- **Symptom:** `terraform apply tfplan` failed with `BucketAlreadyOwnedByYou` after the AWS state had been migrated.
- **Diagnosis:** the same `tfplan` had already been applied. A saved plan is a snapshot ("state is empty, create the bucket") and also records the backend it was made with (local), so re-applying it ignored the S3 state and tried to create the bucket again. AWS refused, so nothing changed, but the run wrote an empty `terraform.tfstate` back to the laptop.
- **Resolution:** confirmed state in S3 was intact (`terraform state list`: 7 resources; `terraform plan`: No changes), then deleted the stale `tfplan` and empty local state.
- **Lesson:** a saved plan is single-use. Always create a fresh `terraform plan -out tfplan` before each apply.

## 9. New subscription "not found" and missing tags right after creation (Phase 3)

- **Symptom:** after Terraform created `sub-cloudctrls-prod`, the Azure CLI reported `Subscription ... not found`, and a follow-up `terraform plan` wanted to add all six tags to the subscription.
- **Diagnosis:** the CLI caches the subscription list from sign-in, so it did not know the new subscription existed. The tags were sent at creation but were not yet visible while Azure finished provisioning the subscription.
- **Resolution:** `az account list --refresh` made the subscription visible. A few minutes later the tags were present (`az tag list --resource-id /subscriptions/<id>`) and `terraform plan` reported no changes, without a second apply.
- **Lesson:** newly created tenant-level objects are eventually consistent. Wait and re-check before re-applying, and refresh local CLI caches after creating subscriptions.

## 10. `aws configure sso`: "Invalid start url provided" (Phase 3)

- **Symptom:** `aws configure sso` failed with `invalid_request: Invalid start url provided`.
- **Diagnosis:** the management account's console URL (`https://<account>.us-west-2.console.aws.amazon.com/...`) was entered. The SSO start URL is the AWS access portal URL, which only exists once Identity Center is enabled. The IAM user sign-in page (`<alias>.signin.aws.amazon.com`) is not it either.
- **Resolution:** after enabling Identity Center and creating the user, used the **AWS access portal URL** (`https://<id>.awsapps.com/start`) from the Identity Center dashboard.
- **Lesson:** AWS has three different sign-in URLs: IAM user sign-in, the console itself, and the Identity Center access portal. Only the last one works for `aws configure sso`.

## 11. `Could not connect to the endpoint URL: "https://sts.json.amazonaws.com/"` (Phase 3)

- **Symptom:** one SSO profile worked; the other failed with an endpoint containing `json`.
- **Diagnosis:** `aws configure get region --profile cloudctrls-mgmt` returned `json`. The region and output-format answers were swapped during `aws configure sso`, so the CLI built the endpoint from the region `json`.
- **Resolution:** `aws configure set region us-west-2 --profile cloudctrls-mgmt` and `aws configure set output json --profile cloudctrls-mgmt`.
- **Lesson:** when an AWS endpoint hostname looks wrong, check the profile's region first.
