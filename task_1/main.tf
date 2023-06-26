
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


#CREATE 3 SUBNETS WITH FOR_EACH - frontend, backend, db
resource "azurerm_subnet" "ksubs" {
  for_each = local.tiers

  name                 = "${each.key}-subnet"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.kvnet.name
  address_prefixes     = ["${each.value}"]
}


resource "azurerm_network_interface" "knics" {
  for_each = local.tiers
  name                = "${each.key}-nic"
  location            = var.location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "${each.key}-nic-config"
    subnet_id                     = azurerm_subnet.ksubs[each.key].id
    private_ip_address_allocation = "Dynamic"
  }
}


output "network_interface_private_ip" {
  description = "virtual network interface private ip"
  value = [for int in azurerm_network_interface.knics: int.private_ip_address ]
}

data "azurerm_network_interface" "fe_private_ip" {
  depends_on = [ azurerm_network_interface.knics ]
  name = "fe-nic"
  resource_group_name = var.rg_name
}

output "fe_private_ip" {
  description = "fe virtual network interface private ip"
  value = "${data.azurerm_network_interface.fe_private_ip.private_ip_address}"
}


#SUBNET-4 FOR APPLICATION GATEWAY
resource "azurerm_subnet" "kags" {
  name                 = "k-ags"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.kvnet.name
  address_prefixes     = ["10.1.4.0/24"]
}


#CREATE A RANDOM PASSWORD FOR 3 VMS
resource "random_password" "vmpass" {
  length = 10
  special = true
  numeric = true
}



resource "azurerm_virtual_machine" "kvms" {
  for_each = local.tiers
  name                  = "${each.key}-vm"
  location              = var.location
  resource_group_name   = var.rg_name
  network_interface_ids = [azurerm_network_interface.knics[each.key].id]
  vm_size               = "Standard_B1s"
  storage_os_disk {
    name              = "${each.key}disk"
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
    computer_name  = "${each.key}-vm"
    admin_username = "${each.key}-vm-user"
    admin_password = "${random_password.vmpass.result}"
  }
#  admin_ssh_key {
#  username = "admin-user"
#  public_key = file(<path-to-.pub>)
#  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
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
  depends_on = [azurerm_network_interface.knics]
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
    ip_addresses = ["${data.azurerm_network_interface.fe_private_ip.private_ip_address}"]
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
