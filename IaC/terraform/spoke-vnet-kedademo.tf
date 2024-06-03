locals {
    spoke-kedaDemo-resource-group = "rg-spoke-kedaDemo"
    spoke-kedaDemo-vnet-address_space = "10.2.0.0/16" # 10.2.0.1 - 10.2.255.254
    spoke-kedaDemo-AKS-address_space = "10.2.0.0/17" # 	10.2.0.1 - 10.2.127.254
    spoke-kedaDemo-AZPass-address_space = "10.2.128.0/17" #10.2.128.1 - 10.2.255.254
    storageaccountname = "sammglogfiles"
    storageaccountcontainername = "logssacontainer" 
    cosmosdbname = "cmmmglogs"
    containerregistryname = "crmmglogs"
    keyvault = "kvmmglogs"
    servicebus = "sbmmglogs"
    sbQueueFiles = "sbQueueFiles"
    sbQueueFilesConnString = "AzureServiceBusFilesconnstr"
    sbQueueLogs = "sbQueueLogs"
    sbQueueLogsConnString = "AzureServiceBusLogsconnstr"
    cosmosdbsqlname = "cosmosdb_sql_database"
    cosmoscontainername = "sql-container"
    
}

# Creating resource group
resource "azurerm_resource_group" "spoke-kedaDemo-vnet-rg" {
    name     = local.spoke-kedaDemo-resource-group
    location = var.location
}

#Creating permissions to the resource group. The hub VM to make changes on cluster because of self-hoted agent. 
resource "azurerm_role_assignment" "vm-hub-self-hosted-user-assigned-permission" {
  scope                = azurerm_resource_group.spoke-kedaDemo-vnet-rg.id
  role_definition_name = "Owner"
  principal_id         = azurerm_user_assigned_identity.vm-self-hosted-user_assigned_id.principal_id
}

# Creating spoke-kedaDemo net, subnets and components inside subnets.
# Creating spoke-kedaDemo vnet
resource "azurerm_virtual_network" "spoke-kedaDemo-vnet" {
    name                = "${var.prefix-spoke-kedaDemo}-vnet"
    location            = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
    resource_group_name = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
    address_space       = ["${local.spoke-kedaDemo-vnet-address_space}"]
}

# Linking vnet with Private DNS Zones
resource "azurerm_private_dns_zone_virtual_network_link" "dnszone-vnet-link-kedaDemo-blob" {
  name                  = "dnszone-vnet-link-kedademo-blob"
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_id    = azurerm_virtual_network.spoke-kedaDemo-vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszone-vnet-link-kedaDemo-cosmos" {
  name                  = "dnszone-vnet-link-kedaDemo-cosmos"
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_id    = azurerm_virtual_network.spoke-kedaDemo-vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszone-vnet-link-kedaDemo-vault" {
  name                  = "dnszone-vnet-link-kedaDemo-vault"
  private_dns_zone_name = azurerm_private_dns_zone.vault.name
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_id    = azurerm_virtual_network.spoke-kedaDemo-vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszone-vnet-link-kedaDemo-acr" {
  name                  = "dnszone-vnet-link-kedaDemo-acr"
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_id    = azurerm_virtual_network.spoke-kedaDemo-vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszone-vnet-link-kedaDemo-aks" {
  name                  = "dnszone-vnet-link-kedaDemo-aks"
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_id    = azurerm_virtual_network.spoke-kedaDemo-vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszone-vnet-link-kedaDemo-sb" {
  name                  = "dnszone-vnet-link-kedaDemo-sb"
  private_dns_zone_name = azurerm_private_dns_zone.sb.name
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  virtual_network_id    = azurerm_virtual_network.spoke-kedaDemo-vnet.id
}

#Configuring peer between vnets
resource "azurerm_virtual_network_peering" "fromkedaDemoToHub" {
  name                      = "peer-${var.prefix-spoke-kedaDemo}-to-${var.prefix-hub}"
  resource_group_name = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  virtual_network_name      = azurerm_virtual_network.spoke-kedaDemo-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.hub-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

#O peering abaixo não deveria precisar - verificar por que.
resource "azurerm_virtual_network_peering" "fromkedaDemoToOnprem" {
  name                      = "peer-${var.prefix-spoke-kedaDemo}-to-${var.prefix-spoke-onprem}"
  resource_group_name = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  virtual_network_name      = azurerm_virtual_network.spoke-kedaDemo-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.spoke-onprem-vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# Creating the spoke-kedaDemo subnet to AKS cluster
resource "azurerm_subnet" "spoke-kedaDemo-subnet-AKS" {
    name                = "${var.prefix-spoke-kedaDemo}-AKS-subnet"
    resource_group_name  = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
    virtual_network_name = azurerm_virtual_network.spoke-kedaDemo-vnet.name
    address_prefixes       = ["${local.spoke-kedaDemo-AKS-address_space}"]
}

# Creating the spoke-kedaDemo subnet to Azure Pass
resource "azurerm_subnet" "spoke-kedaDemo-subnet-AZPass" {
    name                = "${var.prefix-spoke-kedaDemo}-AZPass-subnet"
    resource_group_name  = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
    virtual_network_name = azurerm_virtual_network.spoke-kedaDemo-vnet.name
    address_prefixes       = ["${local.spoke-kedaDemo-AZPass-address_space}"]
}

# Creating storage account where the log files will be copied to
resource "azurerm_storage_account" "logsStorageAccount" {
  name                     = local.storageaccountname
  location            = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
  resource_group_name = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access_enabled = false

  #network_rules {
  #  default_action             = "Allow"
  #  virtual_network_subnet_ids = [azurerm_subnet.hub-subnetothers.id]
  #}



  tags = {
    environment = "Dev"
  }
}

#Creating the SA container
resource "azurerm_storage_container" "logsSAContainer" {
  name                  = local.storageaccountcontainername
  storage_account_name  = azurerm_storage_account.logsStorageAccount.name
  #container_access_type = "blob"
}

#Creating permissions to the storage account. The VM onprem must have access to send logs to storage account
resource "azurerm_role_assignment" "vm-user-assigned-permission" {
  scope                = azurerm_storage_account.logsStorageAccount.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.vm-user_assigned_id.principal_id
}

#The AKS cluster must have access to the storage account to get file and move it to processed container. 
resource "azurerm_role_assignment" "aks-user-assigned-permission-to-sa" {
  scope                = azurerm_storage_account.logsStorageAccount.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.workload-user_assigned_id.principal_id
  #principal_id         = azurerm_kubernetes_cluster.aks-cluster.kubelet_identity[0].object_id
  #principal_id         = azurerm_user_assigned_identity.aks-user_assigned_id.principal_id
}

#Creating the private endpoint to associante to the storage account
resource "azurerm_private_endpoint" "pe-logssa" {
  name                = "pelogssa"
  location            = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
  resource_group_name = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  subnet_id           = azurerm_subnet.spoke-kedaDemo-subnet-AZPass.id

  private_service_connection {
    name                           = "logssa-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.logsStorageAccount.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }
}

resource "azurerm_private_dns_a_record" "dns_a_sta-blob" {
  name                = "sta_a_record-blob"
  zone_name           = azurerm_private_dns_zone.blob.name
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe-logssa.private_service_connection.0.private_ip_address]
}


#Creating Cosmos

#resource "random_integer" "ri" {
#  min = 10000
#  max = 99999
#}

resource "azurerm_cosmosdb_account" "cosmos-db" {
# name                = "logs-cosmos-db-${random_integer.ri.result}"
  name                = local.cosmosdbname
  location            = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
  resource_group_name = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  offer_type          = "Standard"
  public_network_access_enabled = "false"
  #is_virtual_network_filter_enabled = "true"

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
    failover_priority = 0
  }

  #virtual_network_rule {
  #  id = azurerm_subnet.hub-subnetothers.id
  #}

}

resource "azurerm_cosmosdb_sql_database" "cosmosdb_sql_database" {
  name                = local.cosmosdbsqlname
  resource_group_name = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  account_name        = azurerm_cosmosdb_account.cosmos-db.name
}

resource "azurerm_cosmosdb_sql_container" "cosmosdb_sql_container" {
  name                  = local.cosmoscontainername
  resource_group_name = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  account_name        = azurerm_cosmosdb_account.cosmos-db.name
  database_name         = azurerm_cosmosdb_sql_database.cosmosdb_sql_database.name
  partition_key_path    = "/partitionKey"
  partition_key_version = 1
  throughput            = 400

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    included_path {
      path = "/included/?"
    }

    excluded_path {
      path = "/excluded/?"
    }
  }
  
  #unique_key {
  #  paths = ["/definition/idlong", "/definition/idshort"]
  #}
}

resource "azurerm_cosmosdb_sql_role_assignment" "aks-cosmosdb_data_contributor" {
  resource_group_name = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  account_name        = azurerm_cosmosdb_account.cosmos-db.name
  role_definition_id  = data.azurerm_cosmosdb_sql_role_definition.CosmosDBDataContributor.id
  #principal_id        = azurerm_kubernetes_cluster.aks-cluster.kubelet_identity[0].object_id
  principal_id         = azurerm_user_assigned_identity.workload-user_assigned_id.principal_id
  scope               = azurerm_cosmosdb_account.cosmos-db.id
}

resource "azurerm_private_endpoint" "pe-logscdb" {
  name                = "pelogscdb"
  location            = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
  resource_group_name = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  subnet_id           = azurerm_subnet.spoke-kedaDemo-subnet-AZPass.id

  private_service_connection {
    name                           = "logscdb-privateserviceconnection"
    private_connection_resource_id = azurerm_cosmosdb_account.cosmos-db.id
    subresource_names              = ["sql"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "cdb-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }
}

resource "azurerm_private_dns_a_record" "dns_a_sta-sql" {
  name                = "sta_a_record-sql"
  zone_name           = azurerm_private_dns_zone.sql.name
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe-logscdb.private_service_connection.0.private_ip_address]
}

resource "azurerm_kubernetes_cluster" "aks-cluster" {
  name                = var.cluster_name
  location            = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
  resource_group_name = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  dns_prefix_private_cluster = "aks-keda-demo-dns"
  private_cluster_enabled    = true

  #dns_prefix                 = "aks-keda-demo"
  private_dns_zone_id        = azurerm_private_dns_zone.aks.id

  #Activating workload identity
  oidc_issuer_enabled        = true
  workload_identity_enabled  = true

  #Configuring Authentication and Authorization
  role_based_access_control_enabled  = true
  local_account_disabled = true
  azure_active_directory_role_based_access_control {
    managed            = true
    tenant_id          = data.azurerm_subscription.primary.tenant_id
    azure_rbac_enabled = false
    admin_group_object_ids = [azuread_group.aks-admin-group.object_id]
  }

  default_node_pool {
    temporary_name_for_rotation = "userregular"
    name                = "system"
    vm_size             = "Standard_D4as_v4"
    zones  = ["1", "2", "3"]
    enable_auto_scaling       = true
    max_count           = 9
    min_count           = 3
    vnet_subnet_id      = azurerm_subnet.spoke-kedaDemo-subnet-AKS.id

    node_labels = {
      pool_type = "System"
    }
  }

  // o endereçamento tem que comportar o limte de pods por node (conf max 250) x numero de nodes. 
  
  network_profile {
    network_plugin     = "azure"
    #service_cidr       = "10.2.0.0/17" // cluster IP e services. Quantos serviços vou precisar? Esse é o endereçamento reservado para os serviços.  
    #dns_service_ip     = "10.2.0.10" // IP dentro do cluster para resolver dns dos pods e serviços. 
    #pod_cidr = "10.2.0.0/18"  // diferente do service e dns. Esse é, de fato, o endereçamento que será utilizado para alocar no pod
  }

  monitor_metrics {
    annotations_allowed = var.metric_annotations_allowlist
    labels_allowed      = var.metric_labels_allowlist
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks-user_assigned_id.id]
  }

#enabling this will generate an identity automatically
key_vault_secrets_provider {
    secret_rotation_enabled = true
    #secret_identity         = []
  }

workload_autoscaler_profile {
    keda_enabled =  true
  }

}

# Group created for this cluster admin. Do not forget to add users to it. 
resource "azuread_group" "aks-admin-group" {
  //name = var.aks-cluster_admin
  //display_name =  "AKS Cluster Keda-Demo admin group"
  display_name =  var.cluster_admin-group-name
  description       = "Adming group for aks keda-demo using Terraform"
  owners            = [data.azurerm_client_config.current.object_id]
  security_enabled  = true
}

#Adding user to the group
#resource "azuread_group_member" "aks-admin-user" {
#  group_object_id  = azuread_group.aks-admin-group.id
#  member_object_id = data.azuread_user.aks-user-admin.id
#}

#resource "azurerm_kubernetes_cluster_identity" "example" {
#  kubernetes_cluster_id = azurerm_kubernetes_cluster.example.id
#
#  identity {
#    type = "UserAssigned"
#    user_assigned_identity_id = azurerm_user_assigned_identity.example.id
#  }
#}

resource "azurerm_resource_policy_assignment" "aks-keda-demo-resource-limit" {
  name                 = "AKS Resource Limit"
  resource_id          = azurerm_kubernetes_cluster.aks-cluster.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e345eecc-fa47-480f-9e88-67dcc122b164"
  parameters = <<PARAMS
    {
      "cpuLimit": {
        "value": "1000m"
      },
      "memoryLimit": {
        "value": "4Gi"
      }
    }
PARAMS
}

/*resource "azurerm_kubernetes_cluster_addon_profile" "aksaddon" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks-cluster.id
  #kube_dashboard {
  #  enabled = true
  #}

  keda {
    enabled = true
  }
}*/

resource "azurerm_kubernetes_cluster_node_pool" "user_spot" {
  name                  = "userspot"
  mode                  =  "User"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks-cluster.id
  zones                 = ["1", "2", "3"]
  vm_size               = "Standard_B8ms"
  //priority              = "Spot"
  priority              = "Regular"
  //eviction_policy       = "Delete"
  node_taints           = [ "kubernetes.azure.com/scalesetpriority=spot:NoSchedule" ]
  vnet_subnet_id        = azurerm_subnet.spoke-kedaDemo-subnet-AKS.id
  max_count             = 8
  min_count             = 3
  enable_auto_scaling   = true
  max_pods = 18
  node_labels = {
      pool_type = "User"
      pool_priority = "Spot"
    }
}

resource "azurerm_kubernetes_cluster_node_pool" "user_regular" {
  name                  = "userregular"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks-cluster.id
  zones                 = ["1", "2", "3"]
  vm_size               = "Standard_B8ms"
  //priority              = "Spot"
  priority              = "Regular"
  //eviction_policy       = "Delete"
  vnet_subnet_id        = azurerm_subnet.spoke-kedaDemo-subnet-AKS.id
  max_count             = 4
  min_count             = 3
  enable_auto_scaling   = true
  max_pods = 18
  node_labels = {
      pool_type = "User"
      pool_priority = "Regular"
    }
}

resource "azurerm_kubernetes_cluster_node_pool" "windows" {
  name                  = "win"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks-cluster.id
  vnet_subnet_id        = azurerm_subnet.spoke-kedaDemo-subnet-AKS.id
  zones                 = ["1", "2", "3"]
  vm_size               = "Standard_D2s_v3"
  node_count            = 3
  os_type               = "Windows"
  os_disk_size_gb       = 30
  os_sku               = "Windows2019"
}

#Creating permissions to the identity created when key_vault_secrets_provider is enabled.
resource "azurerm_role_assignment" "key-vault-provider-assigned-permission-adm-aks-cluster" {
  scope                = azurerm_key_vault.kv-kedademo.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = azurerm_user_assigned_identity.workload-user_assigned_id.principal_id
}

resource "azurerm_role_assignment" "key-vault-provider-assigned-permission-office-aks-cluster" {
  scope                = azurerm_key_vault.kv-kedademo.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azurerm_user_assigned_identity.workload-user_assigned_id.principal_id
}

#Creating permissions to keda query metrics
resource "azurerm_role_assignment" "key-workload-identity-keda-metrics" {
  scope                = azurerm_monitor_workspace.amw.id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = azurerm_user_assigned_identity.workload-user_assigned_id.principal_id
}

#Creating permissions to the resource group. The hub VM to make changes on cluster.
resource "azurerm_role_assignment" "vm-hub-user-assigned-permission-aks-cluster-admin" {
  scope                = azurerm_kubernetes_cluster.aks-cluster.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = azurerm_user_assigned_identity.vm-self-hosted-user_assigned_id.principal_id
}

#Creating permissions to the resource group. The hub VM to make changes on cluster.
resource "azurerm_role_assignment" "vm-hub-user-assigned-permission-aks-cluster-rbac-admin" {
  scope                = azurerm_kubernetes_cluster.aks-cluster.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = azurerm_user_assigned_identity.vm-self-hosted-user_assigned_id.principal_id
}

#Creating permissions to the resource group. The hub VM to make changes on cluster.
resource "azurerm_role_assignment" "vm-hub-user-assigned-permission-aks-cluster-user" {
  scope                = azurerm_kubernetes_cluster.aks-cluster.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = azurerm_user_assigned_identity.vm-self-hosted-user_assigned_id.principal_id
}

resource "azurerm_role_assignment" "monitoring" {
  scope                = azurerm_kubernetes_cluster.aks-cluster.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_user_assigned_identity.aks-user_assigned_id.principal_id
  #principal_id         = azurerm_kubernetes_cluster.aks-cluster.oms_agent[0].oms_agent_identity[0].object_id
}

#Permissions required to the user identity aks cluster. 
#resource "azurerm_role_assignment" "aks-user-assigned-permission-to-kv" {
#  scope                = azurerm_key_vault.kv-kedademo.id
#  role_definition_name = "Reader"
#  principal_id         = azurerm_user_assigned_identity.aks-user_assigned_id.principal_id
#  #principal_id         = azurerm_kubernetes_cluster.aks-cluster.kubelet_identity[0].object_id
#}

resource "azurerm_role_assignment" "dns_contributor" {
  scope                = azurerm_private_dns_zone.aks.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.aks-user_assigned_id.principal_id
  #principal_id         = azurerm_kubernetes_cluster.aks-cluster.kubelet_identity[0].object_id

}

resource "azurerm_role_assignment" "network_contributor" {
  scope                = azurerm_virtual_network.spoke-kedaDemo-vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks-user_assigned_id.principal_id
  #principal_id         = azurerm_kubernetes_cluster.aks-cluster.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "monitoring-kublet" {
  scope                = azurerm_kubernetes_cluster.aks-cluster.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_kubernetes_cluster.aks-cluster.kubelet_identity[0].object_id
  #principal_id         = azurerm_user_assigned_identity.aks-user_assigned_id.principal_id
}

#Permissions required to the user identity aks cluster. 
resource "azurerm_role_assignment" "aks-user-assigned-permission-to-kv-kublent" {
  scope                = azurerm_key_vault.kv-kedademo.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.workload-user_assigned_id.principal_id
  #principal_id         = azurerm_kubernetes_cluster.aks-cluster.kubelet_identity[0].object_id
  #principal_id         = azurerm_user_assigned_identity.aks-user_assigned_id.principal_id
}

resource "azurerm_role_assignment" "dns_contributor-kublet" {
  scope                = azurerm_private_dns_zone.aks.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks-cluster.kubelet_identity[0].object_id
  #principal_id         = azurerm_user_assigned_identity.aks-user_assigned_id.principal_id

}

resource "azurerm_role_assignment" "network_contributor-kublet" {
  scope                = azurerm_virtual_network.spoke-kedaDemo-vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks-cluster.kubelet_identity[0].object_id
  #principal_id         = azurerm_user_assigned_identity.aks-user_assigned_id.principal_id
}

resource "azurerm_container_registry" "acr" {
  name                          = local.containerregistryname
  location            = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
  resource_group_name = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  sku                           = "Premium"
  admin_enabled                 = true
  public_network_access_enabled = false
}

resource "azurerm_role_assignment" "acr" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  #principal_id         = azurerm_user_assigned_identity.aks-user_assigned_id.principal_id
  principal_id         = azurerm_kubernetes_cluster.aks-cluster.kubelet_identity[0].object_id
}

resource "azurerm_private_endpoint" "acr" {
  name                = "pe-acr-cac-001"
  location            = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
  resource_group_name = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  subnet_id           = azurerm_subnet.spoke-kedaDemo-subnet-AZPass.id

  private_service_connection {
    name                           = "psc-acr-cac-001"
    private_connection_resource_id = azurerm_container_registry.acr.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdzg-acr-cac-001"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }
}

resource "azurerm_private_dns_a_record" "dns_a_sta-acr" {
  name                = "sta_a_record-acr"
  zone_name           = azurerm_private_dns_zone.acr.name
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.acr.private_service_connection.0.private_ip_address]
}

# Creating Keyvault and private ip, link, etc.
resource "azurerm_key_vault" "kv-kedademo" {
  name                        = local.keyvault
  location            = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
  resource_group_name = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  public_network_access_enabled = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
      "List",
      "Update",
      "Create",
      "Delete",
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Backup",
      "Restore",
      "Purge",
    ]

    storage_permissions = [
      "Get",
      "List",
      "Set",
      "Update",
    ]
  }

    #access_policy {
    #tenant_id = data.azurerm_client_config.current.tenant_id
    #object_id = azurerm_kubernetes_cluster.aks-cluster.kubelet_identity[0].object_id

    #key_permissions = [
    #  "Get",
    #  "List",
    #]

    #secret_permissions = [
    #  "Get",
    #  "List",
    #]

    #storage_permissions = [
    #  "Get",
    #  "List",
    #]
  #}

    access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.workload-user_assigned_id.principal_id

    key_permissions = [
      "Get",
      "List",
    ]

    secret_permissions = [
      "Get",
      "List",
    ]

    storage_permissions = [
      "Get",
      "List",
    ]
  }

}

resource "azurerm_private_endpoint" "pe-kv-kedaDemo" {
  name                = "pekvkedaDemo"
  location            = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
  resource_group_name = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  subnet_id           = azurerm_subnet.spoke-kedaDemo-subnet-AZPass.id
  private_service_connection {
    name                           = "kv-kedademo-privateserviceconnection"
    private_connection_resource_id = azurerm_key_vault.kv-kedademo.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "vault-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.vault.id]
  }
}

resource "azurerm_private_dns_a_record" "dns_a_sta-vault" {
  name                = "sta_a_record-vault"
  zone_name           = azurerm_private_dns_zone.vault.name
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe-kv-kedaDemo.private_service_connection.0.private_ip_address]
}

/*resource "azurerm_key_vault_secret" "kv_secret_servicebus_sender_connstr" {
  name         = "sbsenderconnstr"
  value        = azurerm_servicebus_namespace_authorization_rule.connstring.primary_connection_string
  key_vault_id = azurerm_key_vault.kv-kedademo.id
}*/

resource "azurerm_key_vault_secret" "kv_secret_servicebus_files_connstr" {
  name         = local.sbQueueFilesConnString
  value        = azurerm_servicebus_queue_authorization_rule.filesconnstring.primary_connection_string
  key_vault_id = azurerm_key_vault.kv-kedademo.id
}

resource "azurerm_key_vault_secret" "kv_secret_servicebus_logs_connstr" {
  name         = local.sbQueueLogsConnString
  value        = azurerm_servicebus_queue_authorization_rule.logsconnstring.primary_connection_string
  key_vault_id = azurerm_key_vault.kv-kedademo.id
}

resource "azurerm_key_vault_secret" "kv_secret_servicebus_files_endpoint" {
  name         = "AzureServicesFilesEndpoint"
  value        = azurerm_servicebus_namespace.logFilesServiceBusNamespace.name
  key_vault_id = azurerm_key_vault.kv-kedademo.id
}

resource "azurerm_key_vault_secret" "kv_secret_servicebus_files_queue" {
  name         = "AzureServicebusFilesQueue"
  value        = local.sbQueueFiles
  key_vault_id = azurerm_key_vault.kv-kedademo.id
}

resource "azurerm_key_vault_secret" "kv_secret_servicebus_logs_endpoint" {
  name         = "AzureServicesLogsEndpoint"
  value        = azurerm_servicebus_namespace.logFilesServiceBusNamespace.name
  key_vault_id = azurerm_key_vault.kv-kedademo.id
}

resource "azurerm_key_vault_secret" "kv_secret_servicebus_logs_queue" {
  name         = "AzureServicebusLogsQueue"
  value        = local.sbQueueLogs
  key_vault_id = azurerm_key_vault.kv-kedademo.id
}

resource "azurerm_key_vault_secret" "kv_secret_servicebus_cosmos_db_endpoint" {
  name         = "AzureCosmosDBEndpoint"
  value        = azurerm_cosmosdb_account.cosmos-db.endpoint
  key_vault_id = azurerm_key_vault.kv-kedademo.id
}

resource "azurerm_key_vault_secret" "kv_secret_servicebus_cosmos_db_name" {
  name         = "AzureCosmosDBName"
  value        = local.cosmosdbsqlname
  key_vault_id = azurerm_key_vault.kv-kedademo.id
}

resource "azurerm_key_vault_secret" "kv_secret_servicebus_cosmos_container_name" {
  name         = "AzureCosmosDBContainerName"
  value        = local.cosmoscontainername
  key_vault_id = azurerm_key_vault.kv-kedademo.id
}

resource "azurerm_key_vault_secret" "kv_secret_storageaccount_name" {
  name         = "AzureStorageAccountEndpoint"
  value        = azurerm_storage_account.logsStorageAccount.primary_blob_endpoint
  key_vault_id = azurerm_key_vault.kv-kedademo.id
}

resource "azurerm_key_vault_secret" "kv_secret_servicebus_sa_container_name" {
  name         = "AzureStorageAccountContainerName"
  value        = local.storageaccountcontainername
  key_vault_id = azurerm_key_vault.kv-kedademo.id
}

//Creating ServiceBus
resource "azurerm_servicebus_namespace" "logFilesServiceBusNamespace" {
  name                =  local.servicebus
  location            = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
  resource_group_name = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  sku                 = "Premium"
  #public_network_access_enabled = false

  /*--network_rule_set {
    default_action = "Deny"
    trusted_services_allowed = true
  }*/

  capacity            = 1
  tags = {
    source = "Dev"
  }
}

# Creating queue
resource "azurerm_servicebus_queue" "sbQueueFiles" {
  name         = local.sbQueueFiles
  namespace_id = azurerm_servicebus_namespace.logFilesServiceBusNamespace.id
}

# Creating queue
resource "azurerm_servicebus_queue" "sbQueueLogs" {
  name         = local.sbQueueLogs
  namespace_id = azurerm_servicebus_namespace.logFilesServiceBusNamespace.id
}

//Creating permissions to access servicebus
resource "azurerm_role_assignment" "sbreceiver" {
  scope                = azurerm_servicebus_namespace.logFilesServiceBusNamespace.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = azurerm_user_assigned_identity.workload-user_assigned_id.principal_id
  #principal_id         = azurerm_kubernetes_cluster.aks-cluster.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "sbsenderaks" {
  scope                = azurerm_servicebus_namespace.logFilesServiceBusNamespace.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = azurerm_user_assigned_identity.workload-user_assigned_id.principal_id
  #principal_id         = azurerm_kubernetes_cluster.aks-cluster.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "sbsendereventgrid" {
  scope                = azurerm_servicebus_namespace.logFilesServiceBusNamespace.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = azurerm_eventgrid_system_topic.logFilesEventGridSystemTopic.identity.0.principal_id
}

#Creating private endpoint to Service Bus
resource "azurerm_private_endpoint" "pe-sb-kedaDemo" {
  name                = "pesbkedaDemo"
  location            = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
  resource_group_name = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  subnet_id           = azurerm_subnet.spoke-kedaDemo-subnet-AZPass.id

  private_service_connection {
    name                           = "sb-kedademo-privateserviceconnection"
    private_connection_resource_id = azurerm_servicebus_namespace.logFilesServiceBusNamespace.id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "sb-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sb.id]
  }
}

resource "azurerm_private_dns_a_record" "dns_a_sta-sb" {
  name                = "sta_a_record-sb"
  zone_name           = azurerm_private_dns_zone.sb.name
  resource_group_name = azurerm_resource_group.hub-vnet-rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe-sb-kedaDemo.private_service_connection.0.private_ip_address]
}

/*resource "azurerm_servicebus_namespace_authorization_rule" "connstring" {
  name                = "sbsender_connstring"
  namespace_id      = azurerm_servicebus_namespace.logFilesServiceBusNamespace.id

  listen = true
  send   = true
  manage = false

}*/

resource "azurerm_servicebus_queue_authorization_rule" "filesconnstring" {
  name     = local.sbQueueFilesConnString
  queue_id = azurerm_servicebus_queue.sbQueueFiles.id

  listen = true
  send   = true
  manage = false
}


resource "azurerm_servicebus_queue_authorization_rule" "logsconnstring" {
  name     = local.sbQueueLogsConnString
  queue_id = azurerm_servicebus_queue.sbQueueLogs.id

  listen = true
  send   = true
  manage = false
}

#Creating EventGrid - Topic & Subscription
#EventGrid reacts to every new blob created in the storage account and deliver a related event to Service Bus queue
resource "azurerm_eventgrid_system_topic" "logFilesEventGridSystemTopic" {
  name                   = "logFilesEventGridSystemTopic"
  location               = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
  resource_group_name    = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  source_arm_resource_id = azurerm_storage_account.logsStorageAccount.id
  topic_type             = "Microsoft.Storage.StorageAccounts"

  identity {
    type = "SystemAssigned"
  }

}

resource "azurerm_eventgrid_system_topic_event_subscription" "logFilesEventGridTopicSubscription" {
  name                   = "logFilesEventGridTopicSubscription"
  system_topic           = azurerm_eventgrid_system_topic.logFilesEventGridSystemTopic.name
  resource_group_name    = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  event_delivery_schema  = "CloudEventSchemaV1_0"

  service_bus_queue_endpoint_id = azurerm_servicebus_queue.sbQueueFiles.id

  included_event_types = ["Microsoft.Storage.BlobCreated"]

}

#Enable Azure Monitor managed service for Prometheus - Azure Monitor | Microsoft Learn
#https://learn.microsoft.com/en-us/azure/azure-monitor/containers/prometheus-metrics-enable?tabs=terraform
resource "azurerm_monitor_workspace" "amw" {
  name                   = var.monitor_workspace_name
  location               = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
  resource_group_name    = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
}

resource "azurerm_monitor_data_collection_endpoint" "dce" {
  name                = "MSProm-${azurerm_resource_group.spoke-kedaDemo-vnet-rg.location}-${var.cluster_name}"
  location               = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
  resource_group_name    = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  kind                = "Linux"
}

resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                        = "MSProm-${azurerm_resource_group.spoke-kedaDemo-vnet-rg.location}-${var.cluster_name}"
  location               = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
  resource_group_name    = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce.id
  kind                        = "Linux"

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.amw.id
      name               = var.monitor_account_name
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = [var.monitor_account_name]
  }


  data_sources {
    prometheus_forwarder {
      streams = ["Microsoft-PrometheusMetrics"]
      name    = "PrometheusDataSource"
    }
  }

  description = "DCR for Azure Monitor Metrics Profile (Managed Prometheus)"
  depends_on = [
    azurerm_monitor_data_collection_endpoint.dce
  ]
}

resource "azurerm_monitor_data_collection_rule_association" "dcra" {
  name                    = "MSProm-${azurerm_resource_group.spoke-kedaDemo-vnet-rg.location}-${var.cluster_name}"
  target_resource_id      = azurerm_kubernetes_cluster.aks-cluster.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr.id
  description             = "Association of data collection rule. Deleting this association will break the data collection for this AKS Cluster."
  depends_on = [
    azurerm_monitor_data_collection_rule.dcr
  ]
}

resource "azurerm_dashboard_grafana" "grafana" {
  name                = var.grafana_name
  location               = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
  resource_group_name    = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name

  identity {
    type = "SystemAssigned"
  }

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.amw.id
  }
}

resource "azurerm_role_assignment" "datareaderrole" {
  scope              = azurerm_monitor_workspace.amw.id
  role_definition_id = "/subscriptions/${split("/", azurerm_monitor_workspace.amw.id)[2]}/providers/Microsoft.Authorization/roleDefinitions/b0d8363b-8ddd-447d-831f-62ca05bff136"
  principal_id       = azurerm_dashboard_grafana.grafana.identity.0.principal_id
}

resource "azurerm_monitor_alert_prometheus_rule_group" "node_recording_rules_rule_group" {
  name                = "NodeRecordingRulesRuleGroup-${var.cluster_name}"
  location               = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
  resource_group_name    = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  cluster_name        = var.cluster_name
  description         = "Node Recording Rules Rule Group"
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = [azurerm_monitor_workspace.amw.id,azurerm_kubernetes_cluster.aks-cluster.id]

  rule {
    enabled    = true
    record     = "instance:node_num_cpu:sum"
    expression = <<EOF
count without (cpu, mode) (  node_cpu_seconds_total{job="node",mode="idle"})
EOF
  }
  rule {
    enabled    = true
    record     = "instance:node_cpu_utilisation:rate5m"
    expression = <<EOF
1 - avg without (cpu) (  sum without (mode) (rate(node_cpu_seconds_total{job="node", mode=~"idle|iowait|steal"}[5m])))
EOF
  }
  rule {
    enabled    = true
    record     = "instance:node_load1_per_cpu:ratio"
    expression = <<EOF
(  node_load1{job="node"}/  instance:node_num_cpu:sum{job="node"})
EOF
  }
  rule {
    enabled    = true
    record     = "instance:node_memory_utilisation:ratio"
    expression = <<EOF
1 - (  (    node_memory_MemAvailable_bytes{job="node"}    or    (      node_memory_Buffers_bytes{job="node"}      +      node_memory_Cached_bytes{job="node"}      +      node_memory_MemFree_bytes{job="node"}      +      node_memory_Slab_bytes{job="node"}    )  )/  node_memory_MemTotal_bytes{job="node"})
EOF
  }
  rule {
    enabled = true

    record     = "instance:node_vmstat_pgmajfault:rate5m"
    expression = <<EOF
rate(node_vmstat_pgmajfault{job="node"}[5m])
EOF
  }
  rule {
    enabled    = true
    record     = "instance_device:node_disk_io_time_seconds:rate5m"
    expression = <<EOF
rate(node_disk_io_time_seconds_total{job="node", device!=""}[5m])
EOF
  }
  rule {
    enabled    = true
    record     = "instance_device:node_disk_io_time_weighted_seconds:rate5m"
    expression = <<EOF
rate(node_disk_io_time_weighted_seconds_total{job="node", device!=""}[5m])
EOF
  }
  rule {
    enabled    = true
    record     = "instance:node_network_receive_bytes_excluding_lo:rate5m"
    expression = <<EOF
sum without (device) (  rate(node_network_receive_bytes_total{job="node", device!="lo"}[5m]))
EOF
  }
  rule {
    enabled    = true
    record     = "instance:node_network_transmit_bytes_excluding_lo:rate5m"
    expression = <<EOF
sum without (device) (  rate(node_network_transmit_bytes_total{job="node", device!="lo"}[5m]))
EOF
  }
  rule {
    enabled    = true
    record     = "instance:node_network_receive_drop_excluding_lo:rate5m"
    expression = <<EOF
sum without (device) (  rate(node_network_receive_drop_total{job="node", device!="lo"}[5m]))
EOF
  }
  rule {
    enabled    = true
    record     = "instance:node_network_transmit_drop_excluding_lo:rate5m"
    expression = <<EOF
sum without (device) (  rate(node_network_transmit_drop_total{job="node", device!="lo"}[5m]))
EOF
  }
}

resource "azurerm_monitor_alert_prometheus_rule_group" "kubernetes_recording_rules_rule_group" {
  name                = "KubernetesRecordingRulesRuleGroup-${var.cluster_name}"
  location               = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
  resource_group_name    = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  cluster_name        = var.cluster_name
  description         = "Kubernetes Recording Rules Rule Group"
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = [azurerm_monitor_workspace.amw.id,azurerm_kubernetes_cluster.aks-cluster.id]

  rule {
    enabled    = true
    record     = "node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate"
    expression = <<EOF
sum by (cluster, namespace, pod, container) (  irate(container_cpu_usage_seconds_total{job="cadvisor", image!=""}[5m])) * on (cluster, namespace, pod) group_left(node) topk by (cluster, namespace, pod) (  1, max by(cluster, namespace, pod, node) (kube_pod_info{node!=""}))
EOF
  }
  rule {
    enabled    = true
    record     = "node_namespace_pod_container:container_memory_working_set_bytes"
    expression = <<EOF
container_memory_working_set_bytes{job="cadvisor", image!=""}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=""}))
EOF
  }
  rule {
    enabled    = true
    record     = "node_namespace_pod_container:container_memory_rss"
    expression = <<EOF
container_memory_rss{job="cadvisor", image!=""}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=""}))
EOF
  }
  rule {
    enabled    = true
    record     = "node_namespace_pod_container:container_memory_cache"
    expression = <<EOF
container_memory_cache{job="cadvisor", image!=""}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=""}))
EOF
  }
  rule {
    enabled    = true
    record     = "node_namespace_pod_container:container_memory_swap"
    expression = <<EOF
container_memory_swap{job="cadvisor", image!=""}* on (namespace, pod) group_left(node) topk by(namespace, pod) (1,  max by(namespace, pod, node) (kube_pod_info{node!=""}))
EOF
  }
  rule {
    enabled    = true
    record     = "cluster:namespace:pod_memory:active:kube_pod_container_resource_requests"
    expression = <<EOF
kube_pod_container_resource_requests{resource="memory",job="kube-state-metrics"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) (  (kube_pod_status_phase{phase=~"Pending|Running"} == 1))
EOF
  }
  rule {
    enabled    = true
    record     = "namespace_memory:kube_pod_container_resource_requests:sum"
    expression = <<EOF
sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_requests{resource="memory",job="kube-state-metrics"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~"Pending|Running"} == 1        )    ))
EOF
  }
  rule {
    enabled    = true
    record     = "cluster:namespace:pod_cpu:active:kube_pod_container_resource_requests"
    expression = <<EOF
kube_pod_container_resource_requests{resource="cpu",job="kube-state-metrics"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) (  (kube_pod_status_phase{phase=~"Pending|Running"} == 1))
EOF
  }
  rule {
    enabled    = true
    record     = "namespace_cpu:kube_pod_container_resource_requests:sum"
    expression = <<EOF
sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_requests{resource="cpu",job="kube-state-metrics"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~"Pending|Running"} == 1        )    ))
EOF
  }
  rule {
    enabled    = true
    record     = "cluster:namespace:pod_memory:active:kube_pod_container_resource_limits"
    expression = <<EOF
kube_pod_container_resource_limits{resource="memory",job="kube-state-metrics"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) (  (kube_pod_status_phase{phase=~"Pending|Running"} == 1))
EOF
  }
  rule {
    enabled    = true
    record     = "namespace_memory:kube_pod_container_resource_limits:sum"
    expression = <<EOF
sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_limits{resource="memory",job="kube-state-metrics"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~"Pending|Running"} == 1        )    ))
EOF
  }
  rule {
    enabled    = true
    record     = "cluster:namespace:pod_cpu:active:kube_pod_container_resource_limits"
    expression = <<EOF
kube_pod_container_resource_limits{resource="cpu",job="kube-state-metrics"}  * on (namespace, pod, cluster)group_left() max by (namespace, pod, cluster) ( (kube_pod_status_phase{phase=~"Pending|Running"} == 1) )
EOF
  }
  rule {
    enabled    = true
    record     = "namespace_cpu:kube_pod_container_resource_limits:sum"
    expression = <<EOF
sum by (namespace, cluster) (    sum by (namespace, pod, cluster) (        max by (namespace, pod, container, cluster) (          kube_pod_container_resource_limits{resource="cpu",job="kube-state-metrics"}        ) * on(namespace, pod, cluster) group_left() max by (namespace, pod, cluster) (          kube_pod_status_phase{phase=~"Pending|Running"} == 1        )    ))
EOF
  }
  rule {
    enabled    = true
    record     = "namespace_workload_pod:kube_pod_owner:relabel"
    expression = <<EOF
max by (cluster, namespace, workload, pod) (  label_replace(    label_replace(      kube_pod_owner{job="kube-state-metrics", owner_kind="ReplicaSet"},      "replicaset", "$1", "owner_name", "(.*)"    ) * on(replicaset, namespace) group_left(owner_name) topk by(replicaset, namespace) (      1, max by (replicaset, namespace, owner_name) (        kube_replicaset_owner{job="kube-state-metrics"}      )    ),    "workload", "$1", "owner_name", "(.*)"  ))
EOF
    labels = {
      workload_type = "deployment"
    }
  }
  rule {
    enabled    = true
    record     = "namespace_workload_pod:kube_pod_owner:relabel"
    expression = <<EOF
max by (cluster, namespace, workload, pod) (  label_replace(    kube_pod_owner{job="kube-state-metrics", owner_kind="DaemonSet"},    "workload", "$1", "owner_name", "(.*)"  ))
EOF
    labels = {
      workload_type = "daemonset"
    }
  }
  rule {
    enabled    = true
    record     = "namespace_workload_pod:kube_pod_owner:relabel"
    expression = <<EOF
max by (cluster, namespace, workload, pod) (  label_replace(    kube_pod_owner{job="kube-state-metrics", owner_kind="StatefulSet"},    "workload", "$1", "owner_name", "(.*)"  ))
EOF
    labels = {
      workload_type = "statefulset"
    }
  }
  rule {
    enabled    = true
    record     = "namespace_workload_pod:kube_pod_owner:relabel"
    expression = <<EOF
max by (cluster, namespace, workload, pod) (  label_replace(    kube_pod_owner{job="kube-state-metrics", owner_kind="Job"},    "workload", "$1", "owner_name", "(.*)"  ))
EOF
    labels = {
      workload_type = "job"
    }
  }
  rule {
    enabled    = true
    record     = ":node_memory_MemAvailable_bytes:sum"
    expression = <<EOF
sum(  node_memory_MemAvailable_bytes{job="node"} or  (    node_memory_Buffers_bytes{job="node"} +    node_memory_Cached_bytes{job="node"} +    node_memory_MemFree_bytes{job="node"} +    node_memory_Slab_bytes{job="node"}  )) by (cluster)
EOF
  }
  rule {
    enabled    = true
    record     = "cluster:node_cpu:ratio_rate5m"
    expression = <<EOF
sum(rate(node_cpu_seconds_total{job="node",mode!="idle",mode!="iowait",mode!="steal"}[5m])) by (cluster) /count(sum(node_cpu_seconds_total{job="node"}) by (cluster, instance, cpu)) by (cluster)
EOF
  }
}

resource "azurerm_monitor_alert_prometheus_rule_group" "node_and_kubernetes_recording_rules_rule_group_win" {
  name                = "NodeAndKubernetesRecordingRulesRuleGroup-Win-${var.cluster_name}"
  location               = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
  resource_group_name    = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  cluster_name        = var.cluster_name
  description         = "Node and Kubernetes Recording Rules Rule Group for Windows Nodes"
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = [azurerm_monitor_workspace.amw.id,azurerm_kubernetes_cluster.aks-cluster.id]

  rule {
    enabled    = true
    record     = "node:windows_node_filesystem_usage:"
    expression = <<EOF
max by (instance,volume)((windows_logical_disk_size_bytes{job="windows-exporter"} - windows_logical_disk_free_bytes{job="windows-exporter"}) / windows_logical_disk_size_bytes{job="windows-exporter"})
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_filesystem_avail:"
    expression = <<EOF
max by (instance, volume) (windows_logical_disk_free_bytes{job="windows-exporter"} / windows_logical_disk_size_bytes{job="windows-exporter"})
EOF
  }
  rule {
    enabled    = true
    record     = ":windows_node_net_utilisation:sum_irate"
    expression = <<EOF
sum(irate(windows_net_bytes_total{job="windows-exporter"}[5m]))
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_net_utilisation:sum_irate"
    expression = <<EOF
sum by (instance) ((irate(windows_net_bytes_total{job="windows-exporter"}[5m])))
EOF
  }
  rule {
    enabled    = true
    record     = ":windows_node_net_saturation:sum_irate"
    expression = <<EOF
sum(irate(windows_net_packets_received_discarded_total{job="windows-exporter"}[5m])) + sum(irate(windows_net_packets_outbound_discarded_total{job="windows-exporter"}[5m]))
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_net_saturation:sum_irate"
    expression = <<EOF
sum by (instance) ((irate(windows_net_packets_received_discarded_total{job="windows-exporter"}[5m]) + irate(windows_net_packets_outbound_discarded_total{job="windows-exporter"}[5m])))
EOF
  }
  rule {
    enabled    = true
    record     = "windows_pod_container_available"
    expression = <<EOF
windows_container_available{job="windows-exporter", container_id != ""} * on(container_id) group_left(container, pod, namespace) max(kube_pod_container_info{job="kube-state-metrics", container_id != ""}) by(container, container_id, pod, namespace)
EOF
  }
  rule {
    enabled    = true
    record     = "windows_container_total_runtime"
    expression = <<EOF
windows_container_cpu_usage_seconds_total{job="windows-exporter", container_id != ""} * on(container_id) group_left(container, pod, namespace) max(kube_pod_container_info{job="kube-state-metrics", container_id != ""}) by(container, container_id, pod, namespace)
EOF
  }
  rule {
    enabled    = true
    record     = "windows_container_memory_usage"
    expression = <<EOF
windows_container_memory_usage_commit_bytes{job="windows-exporter", container_id != ""} * on(container_id) group_left(container, pod, namespace) max(kube_pod_container_info{job="kube-state-metrics", container_id != ""}) by(container, container_id, pod, namespace)
EOF
  }
  rule {
    enabled    = true
    record     = "windows_container_private_working_set_usage"
    expression = <<EOF
windows_container_memory_usage_private_working_set_bytes{job="windows-exporter", container_id != ""} * on(container_id) group_left(container, pod, namespace) max(kube_pod_container_info{job="kube-state-metrics", container_id != ""}) by(container, container_id, pod, namespace)
EOF
  }
  rule {
    enabled    = true
    record     = "windows_container_network_received_bytes_total"
    expression = <<EOF
windows_container_network_receive_bytes_total{job="windows-exporter", container_id != ""} * on(container_id) group_left(container, pod, namespace) max(kube_pod_container_info{job="kube-state-metrics", container_id != ""}) by(container, container_id, pod, namespace)
EOF
  }
  rule {
    enabled    = true
    record     = "windows_container_network_transmitted_bytes_total"
    expression = <<EOF
windows_container_network_transmit_bytes_total{job="windows-exporter", container_id != ""} * on(container_id) group_left(container, pod, namespace) max(kube_pod_container_info{job="kube-state-metrics", container_id != ""}) by(container, container_id, pod, namespace)
EOF
  }
  rule {
    enabled    = true
    record     = "kube_pod_windows_container_resource_memory_request"
    expression = <<EOF
max by (namespace, pod, container) (kube_pod_container_resource_requests{resource="memory",job="kube-state-metrics"}) * on(container,pod,namespace) (windows_pod_container_available)
EOF
  }
  rule {
    enabled    = true
    record     = "kube_pod_windows_container_resource_memory_limit"
    expression = <<EOF
kube_pod_container_resource_limits{resource="memory",job="kube-state-metrics"} * on(container,pod,namespace) (windows_pod_container_available)
EOF
  }
  rule {
    enabled    = true
    record     = "kube_pod_windows_container_resource_cpu_cores_request"
    expression = <<EOF
max by (namespace, pod, container) ( kube_pod_container_resource_requests{resource="cpu",job="kube-state-metrics"}) * on(container,pod,namespace) (windows_pod_container_available)
EOF
  }
  rule {
    enabled    = true
    record     = "kube_pod_windows_container_resource_cpu_cores_limit"
    expression = <<EOF
kube_pod_container_resource_limits{resource="cpu",job="kube-state-metrics"} * on(container,pod,namespace) (windows_pod_container_available)
EOF
  }
  rule {
    enabled    = true
    record     = "namespace_pod_container:windows_container_cpu_usage_seconds_total:sum_rate"
    expression = <<EOF
sum by (namespace, pod, container) (rate(windows_container_total_runtime{}[5m]))
EOF
  }
}

resource "azurerm_monitor_alert_prometheus_rule_group" "node_recording_rules_rule_group_win" {
  name                = "NodeRecordingRulesRuleGroup-Win-${var.cluster_name}"
  location               = azurerm_resource_group.spoke-kedaDemo-vnet-rg.location
  resource_group_name    = azurerm_resource_group.spoke-kedaDemo-vnet-rg.name
  cluster_name        = var.cluster_name
  description         = "Node and Kubernetes Recording Rules Rule Group for Windows Nodes"
  rule_group_enabled  = true
  interval            = "PT1M"
  scopes              = [azurerm_monitor_workspace.amw.id,azurerm_kubernetes_cluster.aks-cluster.id]

  rule {
    enabled    = true
    record     = "node:windows_node:sum"
    expression = <<EOF
count (windows_system_system_up_time{job="windows-exporter"})
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_num_cpu:sum"
    expression = <<EOF
count by (instance) (sum by (instance, core) (windows_cpu_time_total{job="windows-exporter"}))
EOF
  }
  rule {
    enabled    = true
    record     = ":windows_node_cpu_utilisation:avg5m"
    expression = <<EOF
1 - avg(rate(windows_cpu_time_total{job="windows-exporter",mode="idle"}[5m]))
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_cpu_utilisation:avg5m"
    expression = <<EOF
1 - avg by (instance) (rate(windows_cpu_time_total{job="windows-exporter",mode="idle"}[5m]))
EOF
  }
  rule {
    enabled    = true
    record     = ":windows_node_memory_utilisation:"
    expression = <<EOF
1 -sum(windows_memory_available_bytes{job="windows-exporter"})/sum(windows_os_visible_memory_bytes{job="windows-exporter"})
EOF
  }
  rule {
    enabled    = true
    record     = ":windows_node_memory_MemFreeCached_bytes:sum"
    expression = <<EOF
sum(windows_memory_available_bytes{job="windows-exporter"} + windows_memory_cache_bytes{job="windows-exporter"})
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_memory_totalCached_bytes:sum"
    expression = <<EOF
(windows_memory_cache_bytes{job="windows-exporter"} + windows_memory_modified_page_list_bytes{job="windows-exporter"} + windows_memory_standby_cache_core_bytes{job="windows-exporter"} + windows_memory_standby_cache_normal_priority_bytes{job="windows-exporter"} + windows_memory_standby_cache_reserve_bytes{job="windows-exporter"})
EOF
  }
  rule {
    enabled    = true
    record     = ":windows_node_memory_MemTotal_bytes:sum"
    expression = <<EOF
sum(windows_os_visible_memory_bytes{job="windows-exporter"})
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_memory_bytes_available:sum"
    expression = <<EOF
sum by (instance) ((windows_memory_available_bytes{job="windows-exporter"}))
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_memory_bytes_total:sum"
    expression = <<EOF
sum by (instance) (windows_os_visible_memory_bytes{job="windows-exporter"})
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_memory_utilisation:ratio"
    expression = <<EOF
(node:windows_node_memory_bytes_total:sum - node:windows_node_memory_bytes_available:sum) / scalar(sum(node:windows_node_memory_bytes_total:sum))
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_memory_utilisation:"
    expression = <<EOF
1 - (node:windows_node_memory_bytes_available:sum / node:windows_node_memory_bytes_total:sum)
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_memory_swap_io_pages:irate"
    expression = <<EOF
irate(windows_memory_swap_page_operations_total{job="windows-exporter"}[5m])
EOF
  }
  rule {
    enabled    = true
    record     = ":windows_node_disk_utilisation:avg_irate"
    expression = <<EOF
avg(irate(windows_logical_disk_read_seconds_total{job="windows-exporter"}[5m]) + irate(windows_logical_disk_write_seconds_total{job="windows-exporter"}[5m]))
EOF
  }
  rule {
    enabled    = true
    record     = "node:windows_node_disk_utilisation:avg_irate"
    expression = <<EOF
avg by (instance) ((irate(windows_logical_disk_read_seconds_total{job="windows-exporter"}[5m]) + irate(windows_logical_disk_write_seconds_total{job="windows-exporter"}[5m])))
EOF
  }
}


