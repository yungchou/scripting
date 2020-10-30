

# Using cloud shell

$vmName = 'EncryptedVM'
$vault = 'javanencKV'

$ade = Get-AzKeyVaultSecret -VaultName $vault `
| where { ($_.Tags.MachineName -eq $vmName) -and ($_.ContentType -match 'BEK') } 

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
