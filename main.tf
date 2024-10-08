provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "Production" {
  name     = "My_Organization"
  location = "Central India"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "Prod_Vnet"
  resource_group_name = azurerm_resource_group.Production.name
  location            = azurerm_resource_group.Production.location
  address_space       = ["192.168.0.0/16"]
}

resource "azurerm_subnet" "Subnet" {
  name                 = "VM_Subnet"
  resource_group_name  = azurerm_resource_group.Production.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.1.0/24"]
}

resource "azurerm_public_ip" "PUB_IP" {
  name                = "VM_Pub_IP"
  resource_group_name = azurerm_resource_group.Production.name
  location            = azurerm_resource_group.Production.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "Prod_NSG"
  location            = azurerm_resource_group.Production.location
  resource_group_name = azurerm_resource_group.Production.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix  = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix  = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix  = "*"
  }
}

resource "azurerm_network_interface" "Nic" {
  name                = "Prod_Nic"
  location            = azurerm_resource_group.Production.location
  resource_group_name = azurerm_resource_group.Production.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.Subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.PUB_IP.id
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.Subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_virtual_machine" "ProdSrv" {
  name                  = "WebSrv"
  location              = azurerm_resource_group.Production.location
  resource_group_name   = azurerm_resource_group.Production.name
  network_interface_ids = [azurerm_network_interface.Nic.id]
  vm_size               = "Standard_B1s"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "WebSrv"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/testadmin/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub")
    }
  }
}

output "public_ip" {
  value = azurerm_public_ip.PUB_IP.ip_address
}