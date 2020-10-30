Select-AzureSubscription "<<SUBSCRIPTION NAME>>" 
     
### Source VHD - authenticated container ###
$srcUri = "<<COMPLITE SOURCE URI FOR THE DISK TO COPY>>" 
     
### Source Storage Account ###
$srcStorageAccount = "<<SOURCE STORAGE ACCOUNT NAME>>"
$srcStorageKey = "<<SOURCE STORAGE ACCOUNT KEY>>"
     
### Target Storage Account ###
$destStorageAccount = "<<DESTINATION STORAGE ACCOUNT NAME>>"
$destStorageKey = "<<DESTINATION STORAGE ACCOUNT KEY>>"
     
### Create the source storage account context ### 
$srcContext = New-AzureStorageContext  –StorageAccountName $srcStorageAccount -StorageAccountKey $srcStorageKey  
     
### Create the destination storage account context ### 
$destContext = New-AzureStorageContext  –StorageAccountName $destStorageAccount -StorageAccountKey $destStorageKey  
     
### Destination Container Name ### 
$containerName = "copiedvhds"
     
### Create the container on the destination ### 
New-AzureStorageContainer -Name $containerName -Context $destContext 
     
### Start the asynchronous copy - specify the source authentication with -SrcContext ### 
$blob1 = Start-AzureStorageBlobCopy -srcUri $srcUri -SrcContext $srcContext -DestContainer $containerName -DestBlob "<<DESTINATION VHD NAME>>" -DestContext $destContext

