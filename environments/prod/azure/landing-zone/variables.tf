variable "subscription_id" {
  description = "Subscription the provider runs in (the one holding the state backend)."
  type        = string
}

variable "billing_scope_id" {
  description = "MCA invoice section the new subscription is billed to."
  type        = string
  sensitive   = true
}

variable "project" {
  description = "Project name used in every resource name."
  type        = string
  default     = "cloudctrls"
}

variable "env" {
  description = "Environment label used in names and tags."
  type        = string
}

variable "location" {
  description = "Azure region (ADR-0005)."
  type        = string
  default     = "eastus"
}

variable "monthly_budget" {
  description = "Monthly budget in USD for the new subscription."
  type        = number
}
