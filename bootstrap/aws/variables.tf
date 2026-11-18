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
  description = "AWS region (ADR-0005)."
  type        = string
  default     = "us-west-2"
}

variable "name_suffix" {
  description = "Short suffix that makes the bucket name globally unique."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{1,5}$", var.name_suffix))
    error_message = "name_suffix must be 1 to 5 lowercase letters or digits."
  }
}
