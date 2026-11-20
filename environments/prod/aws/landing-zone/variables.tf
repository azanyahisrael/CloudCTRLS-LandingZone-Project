variable "project" {
  description = "Project name used in every resource name."
  type        = string
  default     = "cloudctrls"
}

variable "env" {
  description = "Environment label used in names and tags."
  type        = string
}

variable "region" {
  description = "AWS home region (ADR-0005); the region-lock SCP allows it plus us-east-1."
  type        = string
  default     = "us-west-2"
}

variable "workload_account_id" {
  description = "Member account that holds CloudCTRLS prod workloads and the state bucket."
  type        = string
}
