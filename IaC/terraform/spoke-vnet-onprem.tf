locals {
    spoke-onprem-resource-group = "rg-spoke-onprem"
    spoke-onprem-vnet-address_space = "10.1.0.0/24"
    spoke-onprem-subnetLocalMachine-address_space = "10.1.0.64/27"
    vm-onprem-prefix = "onpremVM"
}

# Creating resource group
resource "azurerm_resource_group" "spoke-onprem-vnet-rg" {
    name     = local.spoke-onprem-resource-group
    location = var.location
}

# Creating spoke-onprem net, subnets and components inside subnets.
# Creating spoke-onprem vnet
resource "azurerm_virtual_network" "spoke-onprem-vnet" {
    name                = "${var.prefix-spoke-onprem}-vnet"
    location            = azurerm_resource_group.spoke-onprem-vnet-rg.location
    resource_group_name = azurerm_resource_group.spoke-onprem-vnet-rg.name
    address_space       = ["${local.spoke-onprem-vnet-address_space}"]
   
}

#Linking the vnet to the private DNS
resource "azurerm_private_dns_zone_virtual_network_link" "dnszone-vnet-link-onprem-blob" {
  name                  = "dnszone-vnet-link-onprem-blob"
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_id    = azurerm_virtual_network.spoke-onprem-vnet.id
} 

resource "azurerm_private_dns_zone_virtual_network_link" "dnszone-vnet-link-onprem-cosmos" {
  name                  = "dnszone-vnet-link-onprem-cosmos"
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  resource_group_name  = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_id    = azurerm_virtual_network.spoke-onprem-vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszone-vnet-link-onprem-vault" {
  name                  = "dnszone-vnet-link-onprem-vault"
  private_dns_zone_name = azurerm_private_dns_zone.vault.name
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_id    = azurerm_virtual_network.spoke-onprem-vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszone-vnet-link-onprem-acr" {
  name                  = "dnszone-vnet-link-onprem-acr"
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_id    = azurerm_virtual_network.spoke-onprem-vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszone-vnet-link-onprem-aks" {
  name                  = "dnszone-vnet-link-onprem-aks"
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_id    = azurerm_virtual_network.spoke-onprem-vnet.id
}

#Configuring peer between vnets
resource "azurerm_virtual_network_peering" "fromOnPremToHub" {
  name                      = "peer-${var.prefix-spoke-onprem}-to-${var.prefix-hub}"
  resource_group_name = azurerm_resource_group.spoke-onprem-vnet-rg.name
  virtual_network_name      = azurerm_virtual_network.spoke-onprem-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true

}

#Não deveria precisar desse peering --verificar porque não funcionou.
resource "azurerm_virtual_network_peering" "fromOnPremToKedaDemo" {
  name                      = "peer-${var.prefix-spoke-onprem}-to-${var.prefix-spoke-kedaDemo}"
  resource_group_name = azurerm_resource_group.spoke-onprem-vnet-rg.name
  virtual_network_name      = azurerm_virtual_network.spoke-onprem-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke-kedaDemo-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# Creating the spoke-onprem subnet to simulate on prem vm
resource "azurerm_subnet" "spoke-onprem-subnet-localmachine" {
    name                = "${var.prefix-spoke-onprem}-subnet"
    resource_group_name  = azurerm_resource_group.spoke-onprem-vnet-rg.name
    virtual_network_name = azurerm_virtual_network.spoke-onprem-vnet.name
    address_prefixes       = ["${local.spoke-onprem-subnetLocalMachine-address_space}"]
}

resource "azurerm_network_interface" "onpremvm-nic" {
  name                = "${local.vm-onprem-prefix}-nic"
  location            = azurerm_resource_group.spoke-onprem-vnet-rg.location
  resource_group_name = azurerm_resource_group.spoke-onprem-vnet-rg.name

  ip_configuration {
    name                          = "onpremVmIpConfig"
    subnet_id                     = azurerm_subnet.spoke-onprem-subnet-localmachine.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "onpremvm" {
  name                  = "${local.vm-onprem-prefix}-vm"
  resource_group_name = azurerm_resource_group.spoke-onprem-vnet-rg.name
  location            = azurerm_resource_group.spoke-onprem-vnet-rg.location
  size               = "Standard_DS4_v2"
  admin_username      = "userazure"
  admin_password     = "@Teste123456"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.onpremvm-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.vm-user_assigned_id.id,
    ]
  }

}