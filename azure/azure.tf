# Create a resource group
resource "azurerm_resource_group" "primary" {
  name     = "${var.name}-resources-group"
  location = var.location
}

data "azurerm_subscription" "primary" {
}

data "azurerm_client_config" "current" {
}

resource "azuread_application" "app" {
  display_name = var.name
  owners       = [data.azurerm_client_config.current.object_id]
}

resource "azuread_service_principal" "app" {
  client_id                    = azuread_application.app.client_id
  app_role_assignment_required = false
  owners                       = [data.azurerm_client_config.current.object_id]
}

resource "azuread_service_principal_password" "app" {
  service_principal_id = azuread_service_principal.app.id
  end_date             = "2099-01-01T00:00:00Z"
}

resource "azurerm_role_assignment" "app" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.app.id
}

resource "azurerm_managed_disk" "app" {
  name                 = "${var.name}-disk"
  location             = azurerm_resource_group.primary.location
  resource_group_name  = azurerm_resource_group.primary.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 100
}

resource "azurerm_log_analytics_workspace" "app" {
  name                = "${var.name}-log-analytics"
  location            = azurerm_resource_group.primary.location
  resource_group_name = azurerm_resource_group.primary.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "appinsights" {
  name                = "${var.name}-appinsights"
  resource_group_name = azurerm_resource_group.primary.name
  location            = azurerm_resource_group.primary.location
  application_type    = "web"
}

resource "azurerm_storage_account" "app" {
  name                     = "${var.name}${var.student_id}"
  resource_group_name      = azurerm_resource_group.primary.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
