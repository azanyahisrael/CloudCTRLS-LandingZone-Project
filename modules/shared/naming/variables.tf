variable "project" {
  description = "Project name used in every resource name."
  type        = string
  default     = "cloudctrls"
}

variable "cloud" {
  description = "Cloud the names and tags are for."
  type        = string

  validation {
    condition     = contains(["azure", "aws"], var.cloud)
    error_message = "cloud must be \"azure\" or \"aws\"."
  }
}

variable "env" {
  description = "Environment (ADR-0006: prod now, dev-ready)."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.env)
    error_message = "env must be \"dev\" or \"prod\"."
  }
}

variable "region" {
  description = "Region name as the cloud spells it, e.g. eastus or us-west-2."
  type        = string
}

variable "purpose" {
  description = "What the resources are for, e.g. tfstate, hub, app."
  type        = string
}

variable "name_suffix" {
  description = "Short suffix for globally unique names (storage accounts, S3 buckets)."
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[a-z0-9]{0,5}$", var.name_suffix))
    error_message = "name_suffix must be 0 to 5 lowercase letters or digits."
  }
}
