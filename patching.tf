# 1. Création de la stratégie de Patching (Tous les dimanches à 02h00)
resource "azurerm_maintenance_configuration" "patch_policy" {
  name                     = "mc-patching-sunday-night"
  resource_group_name      = azurerm_resource_group.rg_runops.name
  location                 = azurerm_resource_group.rg_runops.location
  scope                    = "InGuestPatch"
  in_guest_user_patch_mode = "User"

  window {
    start_date_time = "2026-09-20 02:00" 
    time_zone       = "Greenwich Standard Time" 
    duration        = "02:00"                   
    recur_every     = "1Week"                   # Répétition 
  }

  install_patches {
    reboot = "IfRequired" # Redémarre seulement si le patch l'exige
    
    linux {
      classifications_to_include = ["Critical", "Security"]
    }
    
    windows {
      classifications_to_include = ["Critical", "Security"]
    }
  }
}

# 2. Assignation de la stratégie à la VM Linux
resource "azurerm_maintenance_assignment_virtual_machine" "patch_assign_linux" {
  location                     = azurerm_resource_group.rg_runops.location
  maintenance_configuration_id = azurerm_maintenance_configuration.patch_policy.id
  virtual_machine_id           = azurerm_linux_virtual_machine.vm_linux.id
}

# 3. Assignation de la stratégie à la VM Windows
resource "azurerm_maintenance_assignment_virtual_machine" "patch_assign_windows" {
  location                     = azurerm_resource_group.rg_runops.location
  maintenance_configuration_id = azurerm_maintenance_configuration.patch_policy.id
  virtual_machine_id           = azurerm_windows_virtual_machine.vm_windows.id
}