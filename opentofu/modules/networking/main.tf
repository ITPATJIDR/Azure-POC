# ─────────────────────────────────────────────────────────────────────────────
#  modules/networking/main.tf
#  VNet + 4 Subnets + 2 NSGs designed for AKS + ACR on Azure
# ─────────────────────────────────────────────────────────────────────────────

# ── Virtual Network ────────────────────────────────────────────────────────────
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space

  tags = var.tags
}

# ─────────────────────────────────────────────────────────────────────────────
#  Subnets
# ─────────────────────────────────────────────────────────────────────────────

# AKS System Node Pool
resource "azurerm_subnet" "aks_system" {
  name                 = "${var.prefix}-aks-system-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aks_system_subnet_cidr]

  # Required for AKS with Azure CNI
  service_endpoints = ["Microsoft.ContainerRegistry"]
}

# AKS User (Workload) Node Pool
resource "azurerm_subnet" "aks_user" {
  name                 = "${var.prefix}-aks-user-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aks_user_subnet_cidr]

  service_endpoints = ["Microsoft.ContainerRegistry"]
}

# ACR Private Endpoint Subnet
resource "azurerm_subnet" "acr" {
  name                 = "${var.prefix}-acr-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.acr_subnet_cidr]

  # Required to allow Private Endpoint in this subnet
  private_endpoint_network_policies = "Disabled"
  service_endpoints                 = ["Microsoft.ContainerRegistry"]
}

# Management / Bastion Subnet
resource "azurerm_subnet" "management" {
  name                 = "${var.prefix}-management-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.management_subnet_cidr]
}

# ─────────────────────────────────────────────────────────────────────────────
#  NSG: AKS (attached to both aks-system and aks-user subnets)
# ─────────────────────────────────────────────────────────────────────────────
resource "azurerm_network_security_group" "aks" {
  name                = "${var.prefix}-aks-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Allow HTTPS inbound (Kubernetes API server + application ingress)
resource "azurerm_network_security_rule" "aks_allow_https_inbound" {
  name                        = "Allow-HTTPS-Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# Allow HTTP inbound from Internet
resource "azurerm_network_security_rule" "aks_allow_http_inbound" {
  name                        = "Allow-HTTP-Inbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# Allow Kubernetes NodePorts inbound (Azure LB translates 80/443 -> 30000-32767)
resource "azurerm_network_security_rule" "aks_allow_nodeport_inbound" {
  name                        = "Allow-NodePort-Inbound"
  priority                    = 115
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "30000-32767"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# Allow internal VNet traffic (AKS node-to-node, kubelet, etc.)
resource "azurerm_network_security_rule" "aks_allow_vnet_inbound" {
  name                        = "Allow-VNet-Inbound"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# Allow Azure Load Balancer health probes
resource "azurerm_network_security_rule" "aks_allow_lb_inbound" {
  name                        = "Allow-AzureLoadBalancer-Inbound"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# Allow AKS API server communication (node → API server port 443 + 9000 tunnelfront)
resource "azurerm_network_security_rule" "aks_allow_api_server" {
  name                        = "Allow-AKS-APIServer-Outbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["443", "9000"]
  source_address_prefix       = "*"
  destination_address_prefix  = "AzureCloud"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# Allow outbound to PostgreSQL database subnet (Tier 3) on port 5432
resource "azurerm_network_security_rule" "aks_allow_postgres_outbound" {
  name                        = "Allow-PostgreSQL-Outbound"
  priority                    = 115
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = "*"
  destination_address_prefix  = var.database_subnet_cidr
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# Allow outbound to ACR for image pulls
resource "azurerm_network_security_rule" "aks_allow_acr_outbound" {
  name                        = "Allow-ACR-Outbound"
  priority                    = 110
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "MicrosoftContainerRegistry"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# Allow outbound to Azure Monitor (metrics & logs)
resource "azurerm_network_security_rule" "aks_allow_monitor_outbound" {
  name                        = "Allow-AzureMonitor-Outbound"
  priority                    = 120
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "AzureMonitor"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# Deny all other inbound traffic (explicit)
resource "azurerm_network_security_rule" "aks_deny_all_inbound" {
  name                        = "Deny-All-Inbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# ─────────────────────────────────────────────────────────────────────────────
#  NSG: Management (more restrictive — only SSH from known IPs)
# ─────────────────────────────────────────────────────────────────────────────
resource "azurerm_network_security_group" "management" {
  name                = "${var.prefix}-management-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Allow SSH only from whitelisted management CIDR
resource "azurerm_network_security_rule" "mgmt_allow_ssh" {
  name                        = "Allow-SSH-Management"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.management_allowed_cidr
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.management.name
}

# Allow RDP (optional, for Windows nodes)
resource "azurerm_network_security_rule" "mgmt_allow_rdp" {
  name                        = "Allow-RDP-Management"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = var.management_allowed_cidr
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.management.name
}

# Deny all other inbound to management subnet
resource "azurerm_network_security_rule" "mgmt_deny_all_inbound" {
  name                        = "Deny-All-Inbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.management.name
}

# ─────────────────────────────────────────────────────────────────────────────
#  Subnet: Database (Tier 3 — PostgreSQL)
# ─────────────────────────────────────────────────────────────────────────────
resource "azurerm_subnet" "database" {
  name                 = "${var.prefix}-database-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.database_subnet_cidr]

  # PostgreSQL Flexible Server VNet integration requires subnet delegation
  service_endpoints = ["Microsoft.Sql"]

  delegation {
    name = "postgresql-fs-delegation"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
#  NSG: Database — only AKS subnets may reach port 5432
# ─────────────────────────────────────────────────────────────────────────────
resource "azurerm_network_security_group" "database" {
  name                = "${var.prefix}-database-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Allow PostgreSQL only from AKS system node pool
resource "azurerm_network_security_rule" "db_allow_aks_system" {
  name                        = "Allow-AKS-System-PostgreSQL"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = var.aks_system_subnet_cidr
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.database.name
}

# Allow PostgreSQL only from AKS user (workload) node pool
resource "azurerm_network_security_rule" "db_allow_aks_user" {
  name                        = "Allow-AKS-User-PostgreSQL"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = var.aks_user_subnet_cidr
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.database.name
}

# Allow PostgreSQL from management subnet (for DBA access / migrations)
resource "azurerm_network_security_rule" "db_allow_management" {
  name                        = "Allow-Management-PostgreSQL"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = var.management_subnet_cidr
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.database.name
}

# Deny ALL other inbound to database subnet
resource "azurerm_network_security_rule" "db_deny_all_inbound" {
  name                        = "Deny-All-Inbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.database.name
}

# Deny ALL inbound from internet explicitly (defence-in-depth)
resource "azurerm_network_security_rule" "db_deny_internet_inbound" {
  name                        = "Deny-Internet-Inbound"
  priority                    = 4090
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.database.name
}

# ─────────────────────────────────────────────────────────────────────────────
#  NSG Associations
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_subnet_network_security_group_association" "aks_system" {
  subnet_id                 = azurerm_subnet.aks_system.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

resource "azurerm_subnet_network_security_group_association" "aks_user" {
  subnet_id                 = azurerm_subnet.aks_user.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

resource "azurerm_subnet_network_security_group_association" "management" {
  subnet_id                 = azurerm_subnet.management.id
  network_security_group_id = azurerm_network_security_group.management.id
}

resource "azurerm_subnet_network_security_group_association" "database" {
  subnet_id                 = azurerm_subnet.database.id
  network_security_group_id = azurerm_network_security_group.database.id
}

# Note: ACR subnet uses Private Endpoint — no NSG association needed.
