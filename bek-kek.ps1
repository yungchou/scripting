#region [REQUIRED REFERENCE FILE]
$include = "https://zulustore.blob.core.windows.net/public/yc.azure.iaas.v2.0.ps1"
try { iex ($content = (New-Object Net.WebClient).DownloadString($include)) }
catch { write-host "Error while loading `n$include" -b black -f red; throw 'ERROR!' }
Write-Host "Included the file, `n$include" -b black -f green
#endregion

# Session Tag
prefix='yc'
tag=$initial$(date +%M%S)

#region [SET UP TEST VM]

rgName=$tag
vmName=%tsg"-vm"

region='southcentralus'
vmImg='win2016datacenter'
#vmImage='ubuntults'

az group create -n $rgName --location $region
: '
az group delete -n $rgName --no-wait -y
az configure --defaults group=$rgName
'

az vm create -n $vmName -g $rgName --image $vmImg 
az vm show -n $vmName -g $rgName -o table

# Create a default Ubuntu VM with automatic SSH authentication.
az vm create -n $vmName'U' -g $rgName --image UbuntuLTS --generate-ssh-keys

# Create a vm with cloud-init 
az vm create -n $vmName'C' -g $rgName --image UbuntuLTS --custom-data mySettings.yml

#endregion

#region [RECOVER BEK FROM KEY VAULT]
 
$kvName = '????'
$vmName = '????'
$restoredBEK = 'a:\b\c.bek'

Get-AzKeyVaultSecret -VaultName $kvName `
| where { $_.Tags.Values -like $vmName }

$keyVaultSecret = Get-AzKeyVaultSecret `
    -VaultName $kvName `
    -Name 'the name of a secret to get'

$bekSecretBase64 = $keyVaultSecret.SecretValueText

$bekFileBytes = [Convert]::FromBase64String($bekSecretbase64)
$path = $restoredBEK
[System.IO.File]::WriteAllBytes($path, $bekFileBytes)

#endregion