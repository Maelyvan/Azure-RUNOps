# ---- IP Publique et NIC pour VM Linux (Front) ----
resource "azurerm_public_ip" "pip_linux" {
  name                = "pip-linux-front"
  location            = azurerm_resource_group.rg_runops.location
  resource_group_name = azurerm_resource_group.rg_runops.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic_linux" {
  name                = "nic-linux-front"
  location            = azurerm_resource_group.rg_runops.location
  resource_group_name = azurerm_resource_group.rg_runops.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_Linux.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_linux.id
  }
}

# VM Linux (Ubuntu)
resource "azurerm_linux_virtual_machine" "vm_linux" {
  name                            = "vm-linux-web"
  resource_group_name             = azurerm_resource_group.rg_runops.name
  location                        = azurerm_resource_group.rg_runops.location
  size                            = "Standard_B1s" # Petite taille pour limiter les coûts
  admin_username                  = "runopsadmin"
  admin_password                  = random_password.linux_password.result
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.nic_linux.id]
  patch_assessment_mode                                  = "AutomaticByPlatform"
  patch_mode                                             = "AutomaticByPlatform"
  bypass_platform_safety_checks_on_user_schedule_enabled = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.diag_storage.primary_blob_endpoint
  }
}

# ---- NIC pour VM Windows (Back) ----
resource "azurerm_network_interface" "nic_windows" {
  name                = "nic-windows-back"
  location            = azurerm_resource_group.rg_runops.location
  resource_group_name = azurerm_resource_group.rg_runops.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_Windows.id
    private_ip_address_allocation = "Dynamic"
    # Pas d'IP publique, isolée dans le subnet Back
  }
}

# VM Windows
resource "azurerm_windows_virtual_machine" "vm_windows" {
  name                  = "vmwinapp"
  resource_group_name   = azurerm_resource_group.rg_runops.name
  location              = azurerm_resource_group.rg_runops.location
  size                  = "Standard_B2s"
  admin_username        = "runopsadmin"
  admin_password        = random_password.win_password.result
  network_interface_ids = [azurerm_network_interface.nic_windows.id]
  patch_assessment_mode                                  = "AutomaticByPlatform"
  patch_mode                                             = "AutomaticByPlatform"
  bypass_platform_safety_checks_on_user_schedule_enabled = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.diag_storage.primary_blob_endpoint
  }
}