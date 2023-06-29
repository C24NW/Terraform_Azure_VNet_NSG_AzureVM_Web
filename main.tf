terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

#Create Resource Group
resource "azurerm_resource_group" "resource_group_1" {
  name     = "resource_group_1"
  location = "West US"
}

#Create VNet
resource "azurerm_virtual_network" "vnet_1" {
  name                = "vnet_1"
  location            = "West US"
  resource_group_name = azurerm_resource_group.resource_group_1.name
  address_space       = ["10.0.0.0/16"]
  #dns_servers =
}

#Create subnet
resource "azurerm_subnet" "vnet1_subnet1" {
  name                 = "vnet1_subnet1"
  resource_group_name  = azurerm_resource_group.resource_group_1.name
  virtual_network_name = azurerm_virtual_network.vnet_1.name
  address_prefixes     = ["10.0.1.0/24"]
}

#Create Network Security Group
resource "azurerm_network_security_group" "nsg_1" {
  name                = "nsg_1"
  location            = "West US"
  resource_group_name = azurerm_resource_group.resource_group_1.name
}

resource "azurerm_network_security_rule" "rule_1" {
  name                        = "rule_1"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.resource_group_1.name
  network_security_group_name = azurerm_network_security_group.nsg_1.name
}

#Associate NSG 1 and VNet 1 subnet 1
resource "azurerm_subnet_network_security_group_association" "nsg1_subnet1_association" {
  subnet_id                 = azurerm_subnet.vnet1_subnet1.id
  network_security_group_id = azurerm_network_security_group.nsg_1.id
}

#Add public IP addresses
resource "azurerm_public_ip" "public_ip_1" {
  name                = "public_ip_1"
  resource_group_name = azurerm_resource_group.resource_group_1.name
  location            = azurerm_virtual_network.vnet_1.location
  allocation_method   = "Static"
}

#Create network interface
resource "azurerm_network_interface" "nic_1" {
  name                = "nic_1"
  resource_group_name = azurerm_resource_group.resource_group_1.name
  location            = azurerm_virtual_network.vnet_1.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vnet1_subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip_1.id
  }
}

#Create AzureVM
resource "azurerm_linux_virtual_machine" "azurevm_1" {
  name                            = "azurevm1"
  resource_group_name             = azurerm_resource_group.resource_group_1.name
  location                        = azurerm_virtual_network.vnet_1.location
  size                            = "Standard_B1ls"
  admin_username                  = "adminuser"
  admin_password                  = var.admin_password
  disable_password_authentication = false
  user_data                       = base64encode(file("userdata.sh"))
  network_interface_ids           = [azurerm_network_interface.nic_1.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

variable "admin_password" {}






