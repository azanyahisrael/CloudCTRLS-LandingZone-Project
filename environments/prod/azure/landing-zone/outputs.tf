output "management_group_id" {
  value = azurerm_management_group.env.id
}

output "subscription_id" {
  description = "CloudCTRLS prod subscription; also holds the Terraform state backend."
  value       = azurerm_subscription.env.subscription_id
}
