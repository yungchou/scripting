# REF: https://devblogs.microsoft.com/premier-developer/how-to-shrink-a-managed-disk/

$subscriptionId = "yourSubscriptionId"
$rgName = "yourResourceGroupName"
$fromManagedDiskName = "yourManagedDiskName" 

#Provide Shared Access Signature (SAS) expiry duration in seconds e.g. 3600.
$sasExpiryDuration = "3600"

$toStorageAccountName = "yourstorageaccountName"
$toStorageContainerName = "yourstoragecontainername"
$toStorageAccountKey = "yourStorageAccountKey"
$toDestinationVHDFileName = "yourvhdfilename"

Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionId $subscriptionId

#Generate the SAS for the managed disk
$sas = Grant-AzureRmDiskAccess -ResourceGroupName $rgName -DiskName $fromManagedDiskName -Access Read -DurationInSecond $sasExpiryDuration

#Create the context for the storage account which will be used to copy snapshot to the storage account 
$toDestinationContext = New-AzureStorageContext –StorageAccountName $toStorageAccountName -StorageAccountKey $toStorageAccountKey

#Copy the snapshot to the storage account and wait for it to complete
Start-AzureStorageBlobCopy -AbsoluteUri $sas.AccessSAS -DestContainer $toStorageContainerName -DestContext $toDestinationContext -DestBlob $toDestinationVHDFileName
while (($state = Get-AzureStorageBlobCopyState -Context $toDestinationContext -Blob $toDestinationVHDFileName -Container $toStorageContainerName).Status -ne "Success") { $state; Start-Sleep -Seconds 5 }
$state

