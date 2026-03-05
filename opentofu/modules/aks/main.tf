# ─────────────────────────────────────────────────────────────────────────────
#  modules/aks/main.tf
#  AKS Cluster — System + User node pools, Azure CNI, ACR pull, Azure Monitor
# ─────────────────────────────────────────────────────────────────────────────

# ── Log Analytics Workspace (for Container Insights) ─────────────────────────
resource "azurerm_log_analytics_workspace" "aks" {
  name                = "${var.prefix}-aks-logs"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# ── AKS Cluster ───────────────────────────────────────────────────────────────
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.prefix}-aks"
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = "${var.prefix}-aks"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Standard" # Paid tier for 99.95% SLA

  # ── System Node Pool (Tier 1 + Tier 2 system workloads) ─────────────────────
  default_node_pool {
    name            = "system"
    node_count      = var.system_node_count
    vm_size         = var.system_vm_size
    vnet_subnet_id  = var.aks_system_subnet_id
    os_disk_size_gb = 128
    os_disk_type    = "Managed"
    type            = "VirtualMachineScaleSets"
    zones           = ["2", "3"] # southeastasia supports only zones 2 and 3

    # Only system pods run here
    only_critical_addons_enabled = true

    node_labels = {
      "nodepool-type" = "system"
      "tier"          = "infrastructure"
    }

    upgrade_settings {
      max_surge = "33%"
    }
  }

  # ── Identity ──────────────────────────────────────────────────────────────────
  identity {
    type = "SystemAssigned"
  }

  # ── Networking (Azure CNI — required for VNet integration) ───────────────────
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"

    # AKS internal service CIDR — must NOT overlap with VNet
    service_cidr   = "172.16.0.0/16"
    dns_service_ip = "172.16.0.10"
  }

  # ── SSH Access ────────────────────────────────────────────────────────────────
  linux_profile {
    admin_username = var.admin_username
    ssh_key {
      key_data = var.ssh_public_key
    }
  }

  # ── OIDC + Workload Identity ─────────────────────────────────────────────────
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # ── RBAC ─────────────────────────────────────────────────────────────────────
  role_based_access_control_enabled = true

  # ── Azure Monitor / Container Insights ───────────────────────────────────────
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
  }

  tags = var.tags
}

# ── User Node Pool (Tier 1 + Tier 2 application workloads) ───────────────────
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.user_vm_size
  node_count            = var.user_node_count
  vnet_subnet_id        = var.aks_user_subnet_id
  os_disk_size_gb       = 128
  os_disk_type          = "Managed"
  zones                 = ["2", "3"] # southeastasia supports only zones 2 and 3
  mode                  = "User"

  node_labels = {
    "nodepool-type" = "user"
    "tier"          = "application"
  }

  # Taint to keep system pods off this pool
  node_taints = []

  upgrade_settings {
    max_surge = "33%"
  }

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
#  Role Assignments — must be run manually by an account with Owner role
#  (the service principal in az.json only has Contributor, not Owner)
#
#  After apply, run these with an Owner account:
#
#  ACR Pull for AKS kubelet:
#    KUBELET_ID=$(az aks show -g scg-dev-rg -n scg-dev-aks \
#      --query identityProfile.kubeletidentity.objectId -o tsv)
#    ACR_ID=$(az acr show -g scg-dev-rg -n scgdevacr --query id -o tsv)
#    az role assignment create --assignee $KUBELET_ID \
#      --role AcrPull --scope $ACR_ID
#
#  Network Contributor for AKS control plane:
#    CLUSTER_ID=$(az aks show -g scg-dev-rg -n scg-dev-aks \
#      --query identity.principalId -o tsv)
#    VNET_ID=$(az network vnet show -g scg-dev-rg -n scg-dev-vnet --query id -o tsv)
#    az role assignment create --assignee $CLUSTER_ID \
#      --role "Network Contributor" --scope $VNET_ID
# ─────────────────────────────────────────────────────────────────────────────
