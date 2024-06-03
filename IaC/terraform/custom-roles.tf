#resource "azurerm_role_definition" "cosmosDBCustom" {
#    name        = "CUSTOM - CosmosDBData"
#    description = "Allows manage container data in cosmos"
#    scope       = data.azurerm_client_config.current.subscription_id
#    permissions {
#        actions          = ["Microsoft.DocumentDB/databaseAccounts/readMetadata", "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/read", "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/executeQuery", "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/readChangeFeed"]
#        not_actions = []
#    }
#}
