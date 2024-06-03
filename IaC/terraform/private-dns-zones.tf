#Private dns zones
#Hub-spoke
#Remember to link the same private DNS zones to all spokes and hub virtual networks that contain clients
#that need DNS resolution from the zones.

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
}

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
}

resource "azurerm_private_dns_zone" "vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
}

resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
}

resource "azurerm_private_dns_zone" "aks" {
  name                = "privatelink.eastus.azmk8s.io"
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
}

resource "azurerm_private_dns_zone" "sb" {
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
}
