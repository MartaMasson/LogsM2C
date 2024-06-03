variable "location" {
    description = "Location of the resources"
    default     = "eastus"
}

variable "prefix-hub" {
    description = "Prefixo hub vnet"
    default     = "hub"
}

variable "prefix-spoke-onprem" {
    description = "Prefixo onprem vnet"
    default     = "spoke-onprem"
}

variable "prefix-spoke-kedaDemo" {
    description = "Prefixo kedaDemo vnet"
    default     = "spoke-kedaDemo"
}

variable "agent_count" {
  default = 3
}

variable "cluster_name" {
  default = "aks-keda-demo"
}

variable "cluster_admin-group-name" {
  default = "aks-keda-demo-cluster-admin"
}

variable "metric_labels_allowlist" {
  default = null
}

variable "metric_annotations_allowlist" {
  default = null
}

variable "dns_prefix" {
  default = "k8stest"
}

variable "grafana_name" {
  default = "grafana-prometheus"
}

variable "grafana_sku" {
  default = "Standard"
}

variable "grafana_location" {
  default = "eastus"
}

variable "monitor_workspace_name" {
  default = "amwkedademo"
}

variable "monitor_account_name" {
  default = "-ma-kedaDemo"
}

