# ─────────────────────────────────────────────────────────────────────────────
#  modules/loadbalancer/main.tf
#  Standard Public IP + Standard Azure Load Balancer (HTTP + HTTPS)
#  AKS uses this Public IP for its external LoadBalancer service type
# ─────────────────────────────────────────────────────────────────────────────

# ── Public IP Address ─────────────────────────────────────────────────────────
resource "azurerm_public_ip" "lb" {
  name                = "${var.prefix}-lb-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard" # Must match LB SKU
  zones               = ["2", "3"] # southeastasia supports only zones 2 and 3

  domain_name_label = var.dns_label # optional: <dns_label>.<region>.cloudapp.azure.com
  tags              = var.tags
}

# ── Azure Load Balancer ───────────────────────────────────────────────────────
resource "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.lb.id
  }

  tags = var.tags
}

# ── Backend Address Pool (AKS nodes register here via K8s controller) ─────────
resource "azurerm_lb_backend_address_pool" "main" {
  name            = "${var.prefix}-lb-backend-pool"
  loadbalancer_id = azurerm_lb.main.id
}

# ── Health Probe — HTTP ───────────────────────────────────────────────────────
resource "azurerm_lb_probe" "http" {
  name                = "http-probe"
  loadbalancer_id     = azurerm_lb.main.id
  protocol            = "Http"
  port                = 80
  request_path        = "/health"
  interval_in_seconds = 15
  number_of_probes    = 2
}

# ── Health Probe — TCP 443 ────────────────────────────────────────────────────
resource "azurerm_lb_probe" "https" {
  name                = "https-probe"
  loadbalancer_id     = azurerm_lb.main.id
  protocol            = "Tcp"
  port                = 443
  interval_in_seconds = 15
  number_of_probes    = 2
}

# ── LB Rule — HTTP ───────────────────────────────────────────────────────────
resource "azurerm_lb_rule" "http" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "frontend-ip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.http.id
  idle_timeout_in_minutes        = 4
  # Required when an outbound rule shares the same frontend IP config
  disable_outbound_snat = true
}

# ── LB Rule — HTTPS ──────────────────────────────────────────────────────────
resource "azurerm_lb_rule" "https" {
  name                           = "https-rule"
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "frontend-ip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  probe_id                       = azurerm_lb_probe.https.id
  idle_timeout_in_minutes        = 4
  # Required when an outbound rule shares the same frontend IP config
  disable_outbound_snat = true
}

# ── Outbound Rule (SNAT for AKS node egress) ─────────────────────────────────
resource "azurerm_lb_outbound_rule" "aks_outbound" {
  name                     = "aks-outbound"
  loadbalancer_id          = azurerm_lb.main.id
  protocol                 = "All"
  backend_address_pool_id  = azurerm_lb_backend_address_pool.main.id
  allocated_outbound_ports = 1024

  frontend_ip_configuration {
    name = "frontend-ip"
  }
}
