locals {
    hub-resource-group = "rg-hub-vnet"
    hub-vnet-address_space = "10.0.0.0/24"
    hub-subnetOthers-address_space = "10.0.0.0/27"
    hub-subnetBastion-address_space = "10.0.0.64/27"
    vm-hub-prefix = "hub"
}

# Creating resource group
resource "azurerm_resource_group" "hub-vnet-rg" {
    name     = local.hub-resource-group
    location = var.location
}

# Creating hub net, subnets and components inside subnets.
# Creating hub vnet
resource "azurerm_virtual_network" "hub-vnet" {
    name                = "${var.prefix-hub}-vnet"
    location            = azurerm_resource_group.hub-vnet-rg.location
    resource_group_name = azurerm_resource_group.hub-vnet-rg.name
    address_space       = ["${local.hub-vnet-address_space}"]
}

#Linking vnet with Private DNS zone
resource "azurerm_private_dns_zone_virtual_network_link" "dnszone-vnet-link-hub-blob" {
  name                  = "dnszone-vnet-link-hub-blob"
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  resource_group_name  = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_id    = azurerm_virtual_network.hub-vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszone-vnet-link-hub-cosmos" {
  name                  = "dnszone-vnet-link-hub-cosmos"
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  resource_group_name  = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_id    = azurerm_virtual_network.hub-vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszone-vnet-link-hub-vault" {
  name                  = "dnszone-vnet-link-hub-vault"
  private_dns_zone_name = azurerm_private_dns_zone.vault.name
  resource_group_name  = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_id    = azurerm_virtual_network.hub-vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszone-vnet-link-hub-acr" {
  name                  = "dnszone-vnet-link-hub-acr"
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  resource_group_name  = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_id    = azurerm_virtual_network.hub-vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszone-vnet-link-hub-aks" {
  name                  = "dnszone-vnet-link-hub-ks"
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  resource_group_name  = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_id    = azurerm_virtual_network.hub-vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszone-vnet-link-hub-sb" {
  name                  = "dnszone-vnet-link-hub-sb"
  private_dns_zone_name = azurerm_private_dns_zone.sb.name
  resource_group_name  = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_id    = azurerm_virtual_network.hub-vnet.id
}

#Configuring peer between vnets
resource "azurerm_virtual_network_peering" "fromHubToOnPrem" {
  name                      = "peer-${var.prefix-hub}-to-${var.prefix-spoke-onprem}"
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_name      = azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke-onprem-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

#Configuring peer between vnets
resource "azurerm_virtual_network_peering" "fromHubToKedaDemo" {
  name                      = "peer-${var.prefix-hub}-to-${var.prefix-spoke-kedaDemo}"
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_name      = azurerm_virtual_network.hub-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke-kedaDemo-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# Creating the hub subnet to azure bastion (ab)
resource "azurerm_subnet" "hub-subnetab" {
    name                 = "AzureBastionSubnet"
    resource_group_name  = azurerm_resource_group.hub-vnet-rg.name
    virtual_network_name = azurerm_virtual_network.hub-vnet.name
    address_prefixes       = ["${local.hub-subnetBastion-address_space}"]
}

# Creating the hub subnet to others
resource "azurerm_subnet" "hub-subnetothers" {
    name                 = "OthersSubnet"
    resource_group_name  = azurerm_resource_group.hub-vnet-rg.name
    virtual_network_name = azurerm_virtual_network.hub-vnet.name
    address_prefixes       = ["${local.hub-subnetOthers-address_space}"]
}

# Creating public ip for azure bastion
resource "azurerm_public_ip" "pipab" {
  name                = "abhubpip"
  location            = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Creating azure bastion
resource "azurerm_bastion_host" "hubab" {
  name                = "hubazurebastion"
  location            = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name

  sku                 = "Standard"
  tunneling_enabled   = true


    ip_configuration {
      name                 = "hubabconfig"
      subnet_id            = azurerm_subnet.hub-subnetab.id
      public_ip_address_id = azurerm_public_ip.pipab.id
    }
}

resource "azurerm_network_interface" "hub-nic" {
  name                = "${local.vm-hub-prefix}-nic"
  location            = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name

  ip_configuration {
    name                          = "${local.vm-hub-prefix}VmIpConfig"
    subnet_id                     = azurerm_subnet.hub-subnetothers.id
    private_ip_address_allocation = "Dynamic"
  }
}

#vm for selfhost in linux to access the cluster and use as self-host
resource "azurerm_linux_virtual_machine" "adoselfhosted" {
  name                  = "${local.vm-hub-prefix}-vm"
  location            = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  size               = "Standard_DS4_v2"
  admin_username      = "userazure"
  admin_password     = "@Teste123456"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.hub-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.vm-self-hosted-user_assigned_id.id,
    ]
  }
}

resource "azurerm_network_interface" "hub-vm-win-nic" {
  name                = "${local.vm-hub-prefix}-vm-win-nic"
  location            = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name

  ip_configuration {
    name                          = "${local.vm-hub-prefix}VmWinIpConfig"
    subnet_id                     = azurerm_subnet.hub-subnetothers.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create virtual machine for Windows
resource "azurerm_windows_virtual_machine" "adoselfhostedWindows" {
  name                  = "${local.vm-hub-prefix}-vm-win"
  location            = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  size                = "Standard_D2s_v3"
  admin_username      = "userazure"
  admin_password     = "@Teste123456"

  network_interface_ids = [azurerm_network_interface.hub-vm-win-nic.id]

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.vm-self-hosted-user_assigned_id.id,
    ]
  }
}

resource "azurerm_network_interface" "hub-vm-winDesktop-nic" {
  name                = "${local.vm-hub-prefix}-vm-winDesktop-nic"
  location            = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name

  ip_configuration {
    name                          = "${local.vm-hub-prefix}VmWinDesktopIpConfig"
    subnet_id                     = azurerm_subnet.hub-subnetothers.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create virtual machine for Windows
resource "azurerm_windows_virtual_machine" "adoselfhostedWinDesktop" {
  name                  = "${local.vm-hub-prefix}-vm-winDtop"
  location            = azurerm_resource_group.hub-vnet-rg.location
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  size                = "Standard_D2s_v3"
  admin_username      = "userazure"
  admin_password     = "@Teste123456"

  network_interface_ids = [azurerm_network_interface.hub-vm-winDesktop-nic.id]

  os_disk {
    name                 = "myWinDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-11"
    sku       = "win11-21h2-ent"
    version   = "latest"
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.vm-self-hosted-user_assigned_id.id,
    ]
  }

}
