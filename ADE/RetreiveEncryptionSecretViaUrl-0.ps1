
<#
Introducing the new Azure PowerShell Az module
https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az?view=azps-5.0.0

To upgrade from an existing AzureRM install:

1. Uninstall the Azure PowerShell AzureRM module
https://docs.microsoft.com/en-us/powershell/azure/uninstall-az-ps#uninstall-the-azurerm-module

2. Install the Azure PowerShell Az module
https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-5.0.0

3. OPTIONAL: Enable compatibility mode to add aliases for AzureRM cmdlets 
with Enable-AzureRMAlias while you become familiar with the new command set. 
https://docs.microsoft.com/en-us/powershell/module/az.accounts/enable-azurermalias

Migration from AzureRM to Az
https://docs.microsoft.com/en-us/powershell/azure/migrate-from-azurerm-to-az?view=azps-5.0.0
#>

# First authenticated with an intended subscription
# use CloudShell or
# connect-AzureRMaccount
# connect-azaccount

$vmName = 'EncryptedVmName'
$vault = 'keyVaultName'

#$ade = Get-AzureKeyVaultSecret -VaultName $vault `
$ade = Get-AzKeyVaultSecret -VaultName $vault `
| where { ($_.Tags.MachineName -eq $vmName) -and ($_.ContentType -match 'BEK') } 

# Examine the $ade objet and document the disk drive letters with assoicated tags 

$bekName = $ade.Name
# Go to the key vault/Secrets, locate the BEK, and copy 
# the Secret Identifier, i.e. the secret URL, for later passing
# it to RetreiveEncryptionSecretViaUrl.ps1 as $secretUrl

$kekUrl = $ade.Tags.DiskEncryptionKeyEncryptionKeyURL

<# FORMATTED OUTPUT

# Get the Secrets for all VM Drives from Azure Key Vault
Get-AzKeyVaultSecret -VaultName $vault 
| where { ($_.Tags.MachineName -eq $vmName) -and ($_.ContentType -match 'BEK') } `
| Sort-Object -Property Created `
| ft  Created, `
@{Label = "Content Type"; Expression = { $_.ContentType } }, `
@{Label = "Volume"; Expression = { $_.Tags.VolumeLetter } }, `
@{Label = "DiskEncryptionKeyFileName"; Expression = { $_.Tags.DiskEncryptionKeyFileName } }, `
@{Label = "URL"; Expression = { $_.Id } }

#>
