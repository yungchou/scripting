
#############
# POWERSHELL
#############
            
#create you variables
$subName = "SubscriptionName";
$rgname = "ResourceGroupName";
$diskname = "NameofManagedDisk";
$saname = "DestinationStorageAccountName";
$sakey = "DestinationStorageAccountKey";
$destcontainer = "DestinationContainerName";
$destvhd = "DestinationDiskname.vhd";

#Login to your account and choose the necessary subscription
Connect-AzAccount;
Get-AzSubscription
Set-AzContext -SubscriptionId $subName; 

#grant permissions and set destination for copy
$sas = Grant-AzDiskAccess -ResourceGroupName $rgname -DiskName $diskname -DurationInSecond 3600 -Access Read;
$destContext = New-AzStorageContext �StorageAccountName $saname -StorageAccountKey $sakey;
$blobcopy=Start-AzStorageBlobCopy `
    -AbsoluteUri $sas.AccessSAS `
    -DestContainer $destcontainer `
    -DestContext $destContext `
    -DestBlob $destvhd;

Start-AzStorageBlobCopy -AbsoluteUri "http://www.contosointernal.com/planning" -DestContainer "ContosoArchive" -DestBlob "ContosoPlanning2015" -DestContext $Context


# Begin copy and query the status of the copy, 
# It may look like a stream of errors.
# Once copy is complete, this will stop.    
while(($blobCopy | Get-AzStorageBlobCopyState).Status -eq "Pending"){ 
    Start-Sleep -s 30 
    $blobCopy | Get-AzureStorageBlobCopyState
};



