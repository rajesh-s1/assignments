
#CREATE RESOURCE GROUP

resource "azurerm_resource_group" "krg" {
  name = var.rg_name
  location = var.location

  tags = {
    purpose = "assignment"
  }
}


#CREATE VIRTUAL NETWORK

resource "azurerm_virtual_network" "kvnet" {
  name                = "k-vnet"
  location            = var.location
  resource_group_name = var.rg_name
  address_space       = ["10.1.0.0/16", "10.2.0.0/16"]
  depends_on = [azurerm_resource_group.krg]
  tags = {
    purpose = "assignment"
  }
}


#CREATE 3 SUBNETS
#SUBNET-1
resource "azurerm_subnet" "kfes" {
  name                 = "k_fes"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.kvnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

#SUBNET-2
resource "azurerm_subnet" "kbes" {
  name                 = "k_bes"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.kvnet.name
  address_prefixes     = ["10.1.2.0/24"]
}

#SUBNET-3
resource "azurerm_subnet" "kdbs" {
  name                 = "k_dbs"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.kvnet.name
  address_prefixes     = ["10.1.3.0/24"]
}

#SUBNET-4 FOR APPLICATION GATEWAY
resource "azurerm_subnet" "kags" {
  name                 = "k-ags"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.kvnet.name
  address_prefixes     = ["10.1.4.0/24"]
}



#CREATE 3 NETWORK INTERFACE
#NIC-1
resource "azurerm_network_interface" "knic1" {
  name                = "k-nic1"
  location            = var.location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "frontend-tier-NIC"
    subnet_id                     = azurerm_subnet.kfes.id
    private_ip_address_allocation = "Dynamic"
  }
}

#NIC-2
resource "azurerm_network_interface" "knic2" {
  name                = "k-nic2"
  location            = var.location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "backend-tier-NIC"
    subnet_id                     = azurerm_subnet.kbes.id
    private_ip_address_allocation = "Dynamic"
  }
}

#NIC-3
resource "azurerm_network_interface" "knic3" {
  name                = "k-nic3"
  location            = var.location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "db-tier-NIC"
    subnet_id                     = azurerm_subnet.kdbs.id
    private_ip_address_allocation = "Dynamic"
  }
}




#CREATE A RANDOM PASSWORD FOR 3 VMS
resource "random_password" "vmpass" {
  length = 10
  special = true
  numeric = true
}

#CREATE 3 VMS
#VM-1

resource "azurerm_virtual_machine" "kvm1" {
  name                  = "k-vm1"
  location              = var.location
  resource_group_name   = var.rg_name
  network_interface_ids = [azurerm_network_interface.knic1.id]
  vm_size               = "Standard_B1s"
  storage_os_disk {
    name              = "vmdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  os_profile {
    computer_name  = "k-vm1"
    admin_username = "k-vm1-user"
    admin_password = "${random_password.vmpass.result}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}


#VM-2

resource "azurerm_virtual_machine" "kvm2" {
  name                  = "k-vm2"
  location              = var.location
  resource_group_name   = var.rg_name
  network_interface_ids = [azurerm_network_interface.knic2.id]
  vm_size               = "Standard_B1s"
  storage_os_disk {
    name              = "vmdisk2"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  os_profile {
    computer_name  = "k-vm2"
    admin_username = "k-vm2-user"
    admin_password = "${random_password.vmpass.result}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}


#VM-3

resource "azurerm_virtual_machine" "kvm3" {
  name                  = "k-vm3"
  location              = var.location
  resource_group_name   = var.rg_name
  network_interface_ids = [azurerm_network_interface.knic3.id]
  vm_size               = "Standard_B1s"
  storage_os_disk {
    name              = "vmdisk3"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  os_profile {
    computer_name  = "k-vm3"
    admin_username = "k-vm3-user"
    admin_password = "${random_password.vmpass.result}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}


output "fe-vm-private-ip" {
  description = "Private ip of fe vm"
  value = "${azurerm_network_interface.knic1.private_ip_address}"
  #value = "${azurerm_network_interface.knic1.*.private_ip_address}"
}



#PUBLIC IP FOR APPLICATION GATEWAY
resource "azurerm_public_ip" "pip" {
  name                = "p_ip"
  resource_group_name = var.rg_name
  location            = var.location
  allocation_method   = "Dynamic"
}




#APPLICATION GATEWAY 

resource "azurerm_application_gateway" "kag" {
  name                = "k-ag"
  resource_group_name = var.rg_name
  location            = var.location

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway_ip"
    subnet_id = azurerm_subnet.kags.id
  }

  frontend_port {
    name = "fe_port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "fe_ip_config"
    public_ip_address_id = azurerm_public_ip.pip.id
  }

  backend_address_pool {
    name = "be_add_pool"
    ip_addresses = ["${azurerm_network_interface.knic1.private_ip_address}"]
  }

  backend_http_settings {
    name                  = "be_http_set"
    cookie_based_affinity = "Disabled"
    path                  = "/our-app-path/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 120
  }

  http_listener {
    name                           = "k-listener"
    frontend_ip_configuration_name = "fe_ip_config"
    frontend_port_name             = "fe_port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "routing-rules"
    rule_type                  = "Basic"
    http_listener_name         = "k-listener"
    backend_address_pool_name  = "be_add_pool"
    backend_http_settings_name = "be_http_set"
  }
}