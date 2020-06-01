# Connect to Azure
Disable-AzContextAutosave –Scope Process
$connection = Get-AutomationConnection -Name AzureRunAsConnection
while (!($connectionResult) -And ($LogonAttempt -le 10)) {
  Write-Output "Connecting to Azure..."
  $LogonAttempt++
  # Logging in to Azure...
  $connectionResult = Connect-AzAccount `
    -ServicePrincipal `
    -Tenant $connection.TenantID `
    -ApplicationID $connection.ApplicationID `
    -CertificateThumbprint $connection.CertificateThumbprint

  Start-Sleep -Seconds 30
}
Write-Output "Connected"

# Define all VMs names
#$vmNameArrProd = @("FG-APP", "B2C-PROD", "FGN-B2C-PROD", "NCP", "FG-APP-SRV01")
$vmNameArr = @("da-stage-fg-app", "da-stage-b2c", "da-stage-fgn-b2c", "da-stage-ncp")
$storageAccountName = "automationstoracc"
$containerName = "logsfromvms"
$extensionFileName = "stagingExtension.ps1"

# Set Custom Script Extension for each VM
foreach ($vmName in $vmNameArr) {
  try {
    $resourceGroupName = (Get-AzVM -Name $vmName).ResourceGroupName
    $vmLocation = (Get-AzVM -Name $vmName).Location
    $vmState = (Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -Status -ErrorAction Stop).Statuses[1].Code
    if ($vmState -eq "PowerState/deallocating" -or $vmState -eq "PowerState/deallocated") {
      continue
    }
  }
  catch {
    Write-Output ("Get VM Parameters Error! Details:`n$_")
    continue
  }
  # Automate Access Key
  try {
    $storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName "ntt-firstgen-group" -AccountName $storageAccountName -ErrorAction Stop)
  }
  catch {
    Write-Output "Get Access Key Error! Details:`n$_"
    break
  }
  for ($i = 0; $i -lt $vmNameArr.Length; $i++) {
    try {
      Set-AzVMCustomScriptExtension -ResourceGroupName $resourceGroupName -Location $vmLocation -VMName $vmName -Name "moveAndDeleteLogsExtensionStaging" -TypeHandlerVersion "1.1" -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey.Value[$i] -FileName $extensionFileName -ContainerName $containerName
      Start-Sleep -Seconds 10
      break
    }
    catch {
      Write-Output "Key$i not found`n$_"
    }
  }
}