# Compte de stockage pour les diagnostics de démarrage des VMs
resource "azurerm_storage_account" "diag_storage" {
  name                     = "diagstgrunops${random_id.random.hex}"
  resource_group_name      = azurerm_resource_group.rg_runops.name
  location                 = azurerm_resource_group.rg_runops.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "random_id" "random" {
  byte_length = 4
}

# Génération d'un mot de passe sécurisé pour Windows
resource "random_password" "win_password" {
  length           = 16
  special          = true
  override_special = "!#$%&()*+,-./:<=>?@[]^_{|}~"
}

# Génération d'un mot de passe sécurisé pour Linux (si pas de clé SSH)
resource "random_password" "linux_password" {
  length           = 16
  special          = true
}

# Key Vault pour stocker les secrets
resource "azurerm_key_vault" "kv_runops" {
  name                        = "kv-runops-${random_id.random.hex}"
  location                    = azurerm_resource_group.rg_runops.location
  resource_group_name         = azurerm_resource_group.rg_runops.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "List", "Set", "Delete", "Recover", "Purge"]
  }
}

# Sauvegarde des mots de passe dans le Key Vault
resource "azurerm_key_vault_secret" "win_admin_pwd" {
  name         = "WindowsAdminPassword"
  value        = random_password.win_password.result
  key_vault_id = azurerm_key_vault.kv_runops.id
}

resource "azurerm_key_vault_secret" "linux_admin_pwd" {
  name         = "LinuxAdminPassword"
  value        = random_password.linux_password.result
  key_vault_id = azurerm_key_vault.kv_runops.id
}