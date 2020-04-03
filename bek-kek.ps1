#region [RECOVER BEK FROM KEY VAULT]

$kvName = '????'
$vmName = '????'
$restoredBEK = 'a:\b\c.bek'

Get-AzKeyVaultSecret -VaultName $kvName `
| where {$_.Tags.Values -like $vmName}

$keyVaultSecret = Get-AzKeyVaultSecret `
    -VaultName $kvName `
    -Name 'the name of a secret to get'

$bekSecretBase64 = $keyVaultSecret.SecretValueText

$bekFileBytes = [Convert]::FromBase64String($bekSecretbase64)
$path = $restoredBEK
[System.IO.File]::WriteAllBytes($path,$bekFileBytes)

#endregion