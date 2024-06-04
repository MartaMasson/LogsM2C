# Creating as identidades aqui. 
  resource "azurerm_user_assigned_identity" "vm-user_assigned_id" {
    location            = azurerm_resource_group.spoke-onprem-vnet-rg.location
    name                = "${local.vm-onprem-prefix}-vm-user-identity"
    resource_group_name = azurerm_resource_group.spoke-onprem-vnet-rg.name
  }

 resource "azurerm_user_assigned_identity" "aks-user_assigned_id" {
  name                = "aks-user_assigned_id"
  location            = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
  resource_group_name = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
}

  resource "azurerm_user_assigned_identity" "vm-self-hosted-user_assigned_id" {
    location            = azurerm_resource_group.spoke-onprem-vnet-rg.location
    name                = "${local.vm-hub-prefix}-vm-user-identity"
    resource_group_name = azurerm_resource_group.spoke-onprem-vnet-rg.name
  }

  resource "azurerm_user_assigned_identity" "workload-user_assigned_id" {
    location            = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
    resource_group_name = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
    name                = "aks-wl-user-identity"
  }
