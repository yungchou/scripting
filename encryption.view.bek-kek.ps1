## AZ module version

if ((Get-AzContext) -ne $Null) {

  $vmName = 'vm1'
  $vault = 'zookv'
  
  # Get the Secrets for all VM Drives from Azure Key Vault
  Get-AzKeyVaultSecret -VaultName $vault | where { ($_.Tags.MachineName -eq $vmName) -and ($_.ContentType -match 'BEK') } `
  | Sort-Object -Property Created `
  | ft  Created, `
  @{Label = "Content Type"; Expression = { $_.ContentType } }, `
  @{Label = "Volume"; Expression = { $_.Tags.VolumeLetter } }, `
  @{Label = "DiskEncryptionKeyFileName"; Expression = { $_.Tags.DiskEncryptionKeyFileName } }, `
  @{Label = "URL"; Expression = { $_.Id } }
}
else {
  Write-Output "Please log in first with Add-AzAccount"
}

# ----------------------------------------------
## AzureRM version
Login-AzureRmAccount
  
$vmName = 'vm1'
$vault = 'zookv'
  
# Get the Secrets for all VM Drives from Azure Key Vault
Get-AzureKeyVaultSecret -VaultName $vault | where { ($_.Tags.MachineName -eq $vmName) -and ($_.ContentType -match 'BEK') } `
| Sort-Object -Property Created `
| ft  Created, `
@{Label = "Content Type"; Expression = { $_.ContentType } }, `
@{Label = "Volume"; Expression = { $_.Tags.VolumeLetter } }, `
@{Label = "DiskEncryptionKeyFileName"; Expression = { $_.Tags.DiskEncryptionKeyFileName } }

