# 1. Log Analytics Workspace (Le centre de collecte des logs)
resource "azurerm_log_analytics_workspace" "law_runops" {
  name                = "law-runops-${random_id.random.hex}"
  location            = azurerm_resource_group.rg_runops.location
  resource_group_name = azurerm_resource_group.rg_runops.name
  sku                 = "PerGB2018"
  retention_in_days   = 30 # 
}

# 2. Groupe d'action 
resource "azurerm_monitor_action_group" "ag_critical" {
  name                = "ag-critical-runops"
  resource_group_name = azurerm_resource_group.rg_runops.name
  short_name          = "CritAlerts"

# Action déclenchée : Appeler le Runbook d'auto-remédiation
  webhook_receiver {
    name                    = "call-runbook-webhook"
    service_uri             = azurerm_automation_webhook.webhook_restart_vm.uri
    use_common_alert_schema = true # Format standardisé pour que le script puisse le lire
  }  
}

# 3. Règle d'alerte : Détection d'un pic CPU > 90% sur la VM Linux
resource "azurerm_monitor_metric_alert" "cpu_alert_linux" {
  name                = "alert-cpu-90-linux"
  resource_group_name = azurerm_resource_group.rg_runops.name
  scopes              = [azurerm_linux_virtual_machine.vm_linux.id]
  description         = "Alerte déclenchée si le CPU dépasse 90% pendant 5 minutes."
  severity            = 1 # Sévérité Haute

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 90
  }
  
  window_size = "PT5M" # Fenêtre d'évaluation de 5 minutes

  action {
    action_group_id = azurerm_monitor_action_group.ag_critical.id
  }
}