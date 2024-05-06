# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# To create the resource group named AZ-900
resource "azurerm_resource_group" "rc_group" {
  name     = "AZ-900"
  location = "east us"
  tags = {
    environment = "dev"
  }
}

# Generate a random string for use in the domain name label
resource "random_string" "fqdn" {
  length  = 6
  special = false
  upper   = false
  numeric = false
}

# Create a virtual network
resource "azurerm_virtual_network" "anuj-enchanted-vn" {
  name                = "enchanted-virtual-network"
  resource_group_name = azurerm_resource_group.rc_group.name
  location            = azurerm_resource_group.rc_group.location
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "dev"
  }
}

# Create a subnet within the virtual network
resource "azurerm_subnet" "enchanted_subnet" {
  name                 = "enchanted_subnet"
  resource_group_name  = azurerm_resource_group.rc_group.name
  virtual_network_name = azurerm_virtual_network.anuj-enchanted-vn.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create a public IP address for lb
resource "azurerm_public_ip" "enchanted_pia" {
  name                    = "enchanted-pia"
  location                = azurerm_resource_group.rc_group.location
  resource_group_name     = azurerm_resource_group.rc_group.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  domain_name_label       = random_string.fqdn.result

  tags = {
    environment = "dev"
  }
}

# Create a load balancer
resource "azurerm_lb" "enchanted-lb" {
  name                = "Enchanted-LoadBalancer"
  location            = azurerm_resource_group.rc_group.location
  resource_group_name = azurerm_resource_group.rc_group.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.enchanted_pia.id
  }
}

# Create a backend address pool for the load balancer
resource "azurerm_lb_backend_address_pool" "backend-address-pool" {
  loadbalancer_id = azurerm_lb.enchanted-lb.id
  name            = "BackEndAddressPool"
}

# Create a probe for the load balancer
resource "azurerm_lb_probe" "lb-probe" {
  loadbalancer_id = azurerm_lb.enchanted-lb.id
  name            = "ssh-running-probe"
  port            = 22
}

# Create a rule for the load balancer
resource "azurerm_lb_rule" "lb-rule" {
  loadbalancer_id                = azurerm_lb.enchanted-lb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
}

# Create a virtual machine scale set
resource "azurerm_linux_virtual_machine_scale_set" "enchanted-vmss" {
  name                = "enchanted-vmss"
  resource_group_name = azurerm_resource_group.rc_group.name
  location            = azurerm_resource_group.rc_group.location
  sku                 = "Standard_B1s"
  instances           = 2
  admin_username      = "anujsubedi"

  admin_ssh_key {
    username   = "anujsubedi"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "enchanted-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.enchanted_subnet.id
    }
  }
}

# Create a public IP address for the virtual machine
resource "azurerm_public_ip" "enchanted_pi" {
  name                = "enchanted-public-ip"
  location            = azurerm_resource_group.rc_group.location
  resource_group_name = azurerm_resource_group.rc_group.name
  allocation_method   = "Static"
  domain_name_label   = "${random_string.fqdn.result}-ssh"
}


# Create a network interface for the virtual machine
resource "azurerm_network_interface" "enchanted-nic" {
  name                = "enchanted-nic"
  location            = azurerm_resource_group.rc_group.location
  resource_group_name = azurerm_resource_group.rc_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.enchanted_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.enchanted_pi.id
  }
  tags = {
    environment = "dev"
  }
}

# Create a virtual machine
resource "azurerm_linux_virtual_machine" "enchanted-vm" {
  name                = "anuj-enchanted-vm"
  resource_group_name = azurerm_resource_group.rc_group.name
  location            = azurerm_resource_group.rc_group.location
  size                = "Standard_B1s"
  admin_username      = "anujsubedi"
  network_interface_ids = [
    azurerm_network_interface.enchanted-nic.id,
  ]

  admin_ssh_key {
    username   = "anujsubedi"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}


