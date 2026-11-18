# NIST SP 800-53 Control Mapping

Controls are listed only once something in the repository supports them. Status is **Partial** until enforcement is automated and tested.

| Control | Name | How CloudCTRLS supports it | Status | Evidence |
|---|---|---|---|---|
| IA-5(7) | No Embedded Unencrypted Static Authenticators | `.gitignore` excludes `.env` files, keys, certificates, `*.tfvars` and Terraform state so credentials are not committed. Storage account keys are disabled on the state backend, so no shared secret exists for it. Automated secret scanning (Gitleaks) is planned for Phase 7. | Partial | [Phase 1, Step 2](../implementation/phase-1-foundation.md#step-2-repository-safety-files) |
| IA-2(1) | Multi-Factor Authentication to Privileged Accounts | MFA enabled on the AWS root user and enforced for the Azure administrator account. Will extend to every human admin identity when IAM Identity Center and Entra ID roles are set up in Phase 3. | Partial | [Phase 2, Step 2](../implementation/phase-2-terraform-foundation.md#step-2-account-safety-before-billable-resources) |
| SC-28 | Protection of Information at Rest | Terraform state (which can contain secrets) is stored encrypted with Azure Storage infrastructure (double) encryption, private container, TLS 1.2 in transit. | Partial | [Phase 2, Step 4a](../implementation/phase-2-terraform-foundation.md#step-4a-azure-state-backend) |
| CP-9 | System Backup | State blob versioning and 30-day soft delete allow recovery from corruption or deletion; a `CanNotDelete` lock protects the storage account. | Partial | [Phase 2, Step 4a](../implementation/phase-2-terraform-foundation.md#step-4a-azure-state-backend) |
