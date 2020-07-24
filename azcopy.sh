# https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10
# https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-blobs
# https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-files

storeName='zoostore' # storage account name
containerName='abc' # blob container name

# Create blob container
sasToken='??'
azcopy make "$storeName.blob.core.windows.net/$containerName?$sasToken"

# Benchmark test
azcopy benchmark 'https://$storeName.blob.core.windows.net/$containerName'


# upload
sourceFile='??'
azcopy copy "$sourceFile" "$storeName.blob.core.windows.net/$containerName?$sasToken"

localDirectory='??'
targetDirectory='??'

azcopy copy "$localDirectory" "$storeName.blob.core.windows.net/$containerName/$targetDirectory?$sasToken" --recursive

azcopy copy "$localDirecotry\*" "$storeName.blob.core.windows.net/$containerName/$targetDirectory?$sasToken" --recursive

# az storage blob copy start-batch -h

key=''
storeAccount=''
sourceBlob=''
sourceContainer=''
destinationBlob='changeme'
destinationContainer=''

az storage blob copy start \
  --source-blob $sourceBlob \
  --source-container $sourceContainer
  --account-name $storeAccount \
  --account-key $key \
  --source-uri "https://$storeAcount.blob.core.windows.net/$sourceContainer" \
  -b $destinationBlob \
  -c $destinationContainer \
  -o table \
  --verbose

# Provide either key or sas token
#  --sas-token $sas \




