output "management_group_id" {
  value = azurerm_management_group.env.id
}

output "subscription_id" {
  description = "Needed in Step 3.2b to move the state backend into this subscription."
  value       = azurerm_subscription.env.subscription_id
}
