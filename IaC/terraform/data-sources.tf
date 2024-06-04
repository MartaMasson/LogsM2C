data "azurerm_subscription" "primary" {
}

data "azurerm_client_config" "current" {}

# Cosmos DB Built-in Data Contributor
# az cosmosdb sql role definition list --account-name cmmmglogs --resource-group rg-spoke-kedaDemo 
data "azurerm_cosmosdb_sql_role_definition" "CosmosDBDataContributor" {
  resource_group_name = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  account_name        = azurerm_cosmosdb_sql_database.cosmosdb_sql_database.account_name
  role_definition_id  = "00000000-0000-0000-0000-000000000002"
}

#data "azuread_group" "aks-admin-group" {
#  display_name = "guimafordev"
#}

data "azuread_user" "aks-user-admin" {
  user_principal_name = "marta.masson@guimafordev.onmicrosoft.com"
}