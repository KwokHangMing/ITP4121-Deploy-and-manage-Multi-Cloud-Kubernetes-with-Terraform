# Create a resource group
resource "azurerm_resource_group" "primary" {
  name     = "${var.name}-resources-group"
  location = var.location
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "primary" {
  name                = "${var.name}-network"
  resource_group_name = azurerm_resource_group.primary.name
  location            = azurerm_resource_group.primary.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet1" {
  name                 = "${var.name}-subnet1"
  resource_group_name  = azurerm_resource_group.primary.name
  virtual_network_name = azurerm_virtual_network.primary.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "subnet2" {
  name                 = "${var.name}-subnet2"
  resource_group_name  = azurerm_resource_group.primary.name
  virtual_network_name = azurerm_virtual_network.primary.name
  address_prefixes     = ["10.0.0.0/24"]
}

