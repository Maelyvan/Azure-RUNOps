# 1. Création de l'Automation Account avec une identité managée (Sécurité Best Practice)
resource "azurerm_automation_account" "aa_runops" {
  name                = "aa-runops-portfolio"
  location            = azurerm_resource_group.rg_runops.location
  resource_group_name = azurerm_resource_group.rg_runops.name
  sku_name            = "Basic"
  
  identity {
    type = "SystemAssigned"
  }
}

# 2. On donne le droit à l'Automation Account de redémarrer les VMs (Rôle de Contributeur)
resource "azurerm_role_assignment" "aa_vm_contributor" {
  scope                = azurerm_resource_group.rg_runops.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_automation_account.aa_runops.identity[0].principal_id
}

# 3. Importation du script PowerShell dans un Runbook
resource "azurerm_automation_runbook" "rb_restart_vm" {
  name                    = "Restart-HighCpuVm"
  location                = azurerm_resource_group.rg_runops.location
  resource_group_name     = azurerm_resource_group.rg_runops.name
  automation_account_name = azurerm_automation_account.aa_runops.name
  log_verbose             = true
  log_progress            = true
  description             = "Auto-remediation N1: Redemarrage VM sur alerte CPU"
  runbook_type            = "PowerShell"

  # On lit le fichier généré localement
  content = file("${path.module}/auto-remediation-restart-vm.ps1")
}

# 4. Création du Webhook (Le déclencheur)
resource "azurerm_automation_webhook" "webhook_restart_vm" {
  name                    = "webhook-restart-vm"
  resource_group_name     = azurerm_resource_group.rg_runops.name
  automation_account_name = azurerm_automation_account.aa_runops.name
  expiry_time             = "2027-12-31T00:00:00Z"
  enabled                 = true
  runbook_name            = azurerm_automation_runbook.rb_restart_vm.name
}