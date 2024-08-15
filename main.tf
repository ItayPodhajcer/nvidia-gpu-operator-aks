provider "azurerm" {
  features {}
}

provider "helm" {
  kubernetes {
    host                   = module.cluster.host
    client_key             = base64decode(module.cluster.client_key)
    client_certificate     = base64decode(module.cluster.client_certificate)
    cluster_ca_certificate = base64decode(module.cluster.cluster_ca_certificate)
  }
}

locals {
  ollama_service_name = "${var.deployment_name}-${random_string.name_suffix.result}"
}

resource "random_string" "name_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.deployment_name}-${var.location}"
  location = var.location
}

module "network" {
  source = "./modules/network"

  name                   = var.deployment_name
  location               = azurerm_resource_group.this.location
  resource_group_name    = azurerm_resource_group.this.name
  destination_port_range = var.ollama_port
}

module "cluster" {
  source = "./modules/cluster"

  name                = var.deployment_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  resource_group_id   = azurerm_resource_group.this.id
  kubernetes_version  = var.kubernetes_version
  subnet_id           = module.network.subnet_id
}

resource "helm_release" "gpu_operator" {
  name             = "gpu-operator"
  repository       = "https://helm.ngc.nvidia.com/nvidia"
  chart            = "gpu-operator"
  version          = var.gpu_operator_chart_version
  namespace        = var.deployment_name
  create_namespace = true

  values = [
    "${templatefile("${path.module}/gpu-operator-values.tpl", {})}"
  ]
}

resource "azurerm_public_ip" "this" {
  name                = "pip-${local.ollama_service_name}-${var.location}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"

  lifecycle {
    ignore_changes = [
      domain_name_label
    ]
  }
}

resource "helm_release" "ollama" {
  name             = local.ollama_service_name
  repository       = "https://otwld.github.io/ollama-helm/"
  chart            = "ollama"
  version          = var.ollama_chart_version
  namespace        = var.deployment_name
  create_namespace = true
  timeout          = 900

  values = [
    "${templatefile("${path.module}/ollama-values.tpl", {
      port           = var.ollama_port
      resource_group = azurerm_resource_group.this.name
      ip_address     = azurerm_public_ip.this.ip_address
      dns_label_name = local.ollama_service_name
    })}"
  ]

  depends_on = [helm_release.gpu_operator]
}
