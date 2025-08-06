provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "xxxxxxxxxx"
  location = "South Africa North"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-internal-apim"
  address_space       = ["xxxxxxxxx"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "apim_subnet" {
  name                 = "snet-apim"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["xxxxxxxxxx"]

  delegation {
    name = "apim-delegation"
    service_delegation {
      name    = "Microsoft.ApiManagement/service"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_network_security_group" "apim_nsg" {
  name                = "nsg-apim"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowInternal"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_address_prefix      = "10.10.0.0/16"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "apim_nsg_assoc" {
  subnet_id                 = azurerm_subnet.apim_subnet.id
  network_security_group_id = azurerm_network_security_group.apim_nsg.id
}

resource "azurerm_api_management" "apim" {
  name                = "xxxxxxxxxxx"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "YourCompany"
  publisher_email     = "api-admin@yourcompany.com"
  sku_name            = "Developer_1"
  virtual_network_type = "Internal"
  virtual_network_configuration {
    subnet_id = azurerm_subnet.apim_subnet.id
  }
}

output "apim_private_ip" {
  value = azurerm_api_management.apim.private_ip_addresses
}
