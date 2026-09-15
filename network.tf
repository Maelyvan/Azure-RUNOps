# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-runops"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg_runops.location
  resource_group_name = azurerm_resource_group.rg_runops.name
}

# Subnet Linux
resource "azurerm_subnet" "subnet_Linux" {
  name                 = "snet-Linux"
  resource_group_name  = azurerm_resource_group.rg_runops.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet Windows
resource "azurerm_subnet" "subnet_Windows" {
  name                 = "snet-Windows"
  resource_group_name  = azurerm_resource_group.rg_runops.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# NSG pour Linux (Autorise web + SSH)
resource "azurerm_network_security_group" "nsg_Linux" {
  name                = "nsg-front"
  location            = azurerm_resource_group.rg_runops.location
  resource_group_name = azurerm_resource_group.rg_runops.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*" # En prod, mettre ton IP publique ici
    destination_address_prefix = "*"
  }
}

# NSG pour Windows (Isolation)
resource "azurerm_network_security_group" "nsg_Windows" {
  name                = "nsg-back"
  location            = azurerm_resource_group.rg_runops.location
  resource_group_name = azurerm_resource_group.rg_runops.name

  security_rule {
    name                       = "Allow-RDP-Internal"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }
}

# Association des NSG aux Subnets
resource "azurerm_subnet_network_security_group_association" "nsg_assoc_Linux" {
  subnet_id                 = azurerm_subnet.subnet_Linux.id
  network_security_group_id = azurerm_network_security_group.nsg_Linux.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc_Windows" {
  subnet_id                 = azurerm_subnet.subnet_Windows.id
  network_security_group_id = azurerm_network_security_group.nsg_Windows.id
}