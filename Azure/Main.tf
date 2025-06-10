
#authanticate with azure account 

provider "azurerm" {
  
features {}
  client_id       =  "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"

  subscription_id = "${var.subscription_id}"
  }

 

# Create a Resource Group
resource "azurerm_resource_group" "resource-group" {
  name     = "resource-group"
  location = "westus"
}

# Create a Virtual Network
resource "azurerm_virtual_network" "virual-network" {
  name                = "vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name
}

# Create a Subnet
resource "azurerm_subnet" "subnetA" {
  name                 = "subnetA"
  resource_group_name  = azurerm_resource_group.resource-group.name
  virtual_network_name = azurerm_virtual_network.virual-network.name
  address_prefixes     = ["10.0.1.0/24"]
}
 
 
# Create a Network Security Group (NSG)
resource "azurerm_network_security_group" "network-security-group" {
  name                = "nsg"
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "RDP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

    security_rule {
    name                       = "HTTP"
    priority                   =300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg-associate" {
  subnet_id = azurerm_subnet.subnetA.id
  network_security_group_id = azurerm_network_security_group.network-security-group.id
  depends_on = [ azurerm_network_security_group.network-security-group ]
  
}


 

# Create a Public IP
resource "azurerm_public_ip" "public-ip" {
  name                = "public-ip"
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name
   allocation_method   = "Static"   # Changed from "Dynamic" to "Static"

  sku                 = "Standard" # Ensure this is set to "Standard"
}

# Create a Network Interface
resource "azurerm_network_interface" "network-interface" {
  name                = "network-interface"
  location            = azurerm_resource_group.resource-group.location
  resource_group_name = azurerm_resource_group.resource-group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public-ip.id
  }
}

# Create an Ubuntu 22.04 VM
resource "azurerm_linux_virtual_machine" "ubuntu-22-04" {
  name                = "ubuntu-22.04"
  resource_group_name = azurerm_resource_group.resource-group.name
  location            = azurerm_resource_group.resource-group.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  admin_password = "${var.admin_password}"
  network_interface_ids = [
    azurerm_network_interface.network-interface.id,
  ]
  #add custome data for the vm 
  custom_data = base64encode(file("bash.sh"))
  # Specify the Ubuntu 22.04 LTS image
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Admin SSH Key for login
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/ssh/sshkey.pub")  # Replace with the path to your SSH public key
  }
    
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
 

  computer_name                  = "ubuntu"
  disable_password_authentication = false
 


}
 
 
  # Output the public IP address of the VM
output "public_ip_address" {
  value = azurerm_public_ip.public-ip
}
 
