# NIST SP 800-53 Control Mapping

Controls are listed only once something in the repository supports them. Status is **Partial** until enforcement is automated and tested.

| Control | Name | How CloudCTRLS supports it | Status | Evidence |
|---|---|---|---|---|
| IA-5(7) | No Embedded Unencrypted Static Authenticators | `.gitignore` excludes `.env` files, keys, certificates, `*.tfvars` and Terraform state so credentials are not committed. Automated secret scanning (Gitleaks) is planned for Phase 7. | Partial | [Phase 1, Step 2](../implementation/phase-1-foundation.md#step-2-repository-safety-files) |
| IA-2(1) | Multi-Factor Authentication to Privileged Accounts | MFA enabled on the AWS root user and enforced for the Azure administrator account. Will extend to every human admin identity when IAM Identity Center and Entra ID roles are set up in Phase 3. | Partial | [Phase 2, Step 2](../implementation/phase-2-terraform-foundation.md#step-2-account-safety-before-billable-resources) |
