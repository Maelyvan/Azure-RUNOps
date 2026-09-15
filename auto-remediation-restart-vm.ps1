
<#
.SYNOPSIS
    Runbook d'auto-remédiation pour redémarrer une machine virtuelle Azure.
.DESCRIPTION
    Ce script est déclenché par une alerte Azure Monitor (via un Action Group).
    Il récupère le nom et le groupe de ressources de la VM depuis le payload de l'alerte
    et exécute un redémarrage (Restart-AzVM) pour résoudre un incident critique (ex: CPU > 90%).
#>

param (
    [object]$WebhookData
)

if ($WebhookData) {
    # 1. Extraction des données de l'alerte depuis le payload JSON
    $alertPayload = (ConvertFrom-Json -InputObject $WebhookData.RequestBody)
    $alertContext = $alertPayload.data.context
    
    # 2. Récupération de l'ID de la ressource concernée (la VM)
    $resourceId = $alertContext.resourceId
    Write-Output "Alerte reçue pour la ressource : $resourceId"
    
    # Extraction du nom du Resource Group et de la VM
    $rgName = ($resourceId -split '/')[4]
    $vmName = ($resourceId -split '/')[8]
    
    Write-Output "Cible identifiée - Resource Group : $rgName, VM : $vmName"
    
    try {
        # 3. Connexion à Azure (Managed Identity recommandée en production)
        # Assurez-vous que l'Automation Account possède les droits "Virtual Machine Contributor"
        Disable-AzContextAutosave -Scope Process
        $AzureContext = (Connect-AzAccount -Identity).context
        
        Write-Output "Connexion Azure réussie. Début de l'auto-remédiation."
        
        # 4. Action de support N1 automatisée : Redémarrage de la VM
        Write-Output "Redémarrage de la machine virtuelle $vmName en cours..."
        Restart-AzVM -ResourceGroupName $rgName -Name $vmName -Force
        
        Write-Output "Auto-remédiation terminée : La VM $vmName a été redémarrée avec succès."
    }
    catch {
        Write-Error "Échec de l'auto-remédiation : $_"
        # Ici, une logique d'escalade N2/ITSM (ex: création de ticket ServiceNow) pourrait être ajoutée
    }
}
else {
    Write-Error "Aucune donnée de Webhook reçue. Ce script doit être appelé par une alerte."
}
