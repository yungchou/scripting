:'
CREATE A CUSTOM IMAGE WITH AN EXISTING AZURE VM
https://docs.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-custom-images

Cloud Shell
https://shell.azure.com/bash
https://shell.azure.com/powershell

STEPS
1. Create a Shared Image Gallery
2. Create an image definition
3. Create an image version
4. Create a VM from the image
5. Share the image gallery
'
az login -o table
az account list -o table

subscriptionId='Visual Studio Enterprise'
az account set --subscription $subscriptionId

# CUSTOMIZATION
prefix='da'

# Session Tag
tag=$prefix$(date +%M%S)

sigRegion='southcentralus'
sigRgName=$tag'_sig_RG'
sigName=$tag'_sig'

# Target region for sharing image
targetRegion='westus'
replicaRegion='eastus'
zone='1'
reolicationType='standard_zrs'

# VM as the image base
baseVmRgName='zulu-vm'
baseVmName='u18'

vmSize='Standard_B2ms'
diskSku='Premium_LRS'

adminID='hendrix'
adminPwd='4testingonly!'


#----------------------------------
# 1. Create a Shared Image Gallery
#----------------------------------
az group create -n $sigRgName -l $sigRegion -o table

: ' 
To clean up
az group delete -n $sigRgName --no-wait -y

To default
az configure --defaults group=$sigRgName
'
az sig create --resource-group $sigRgName --gallery-name $sigName -o table

#----------------------------------
# 2. Create an image definition
#----------------------------------
#az vm list -o table
baseVmId=$(az vm get-instance-view -g $baseVmRgName -n $baseVmName --query id -o tsv)
osType='linux'

# For testing
imageDefinition=$baseVmId'_image_definition'
imagePublisher=$baseVmId'_publisher'
imageOffer=$baseVmId'_offer'
imageSKU=$baseVmId'_SKU'

az sig image-definition create \
   --resource-group $sigRgName \
   --gallery-name $sigName \
   --gallery-image-definition $imageDefinition \
   --publisher $imagePublisher \
   --offer $imageOffer \
   --sku $imageSKU \
   --os-type $osType \
   --os-state specialized

#----------------------------------
# 3. Create an image version
#----------------------------------
subscriptionId=''

az sig image-version create \
   --resource-group $sigRgName \
   --gallery-name $sigName \
   --gallery-image-definition $imageDefinition \
   --gallery-image-version 1.0.0 \  # MajorVersion.MinorVersion.Patch
   --target-regions $targetRegion "$replicaRegion=$zone=$reolicationType" \
   --replica-count 1 \
   --managed-image "/subscriptions/$subscriptionId/resourceGroups/$baseVmRgName/providers/Microsoft.Compute/virtualMachines/$baseVmName" \
   -o table

#----------------------------------
# 4. Create a VM from the image
#----------------------------------
testVmRg=$prefix'-test-RG'
testVmName=$prefix'-test-VM'
testVmRegion='eastus2'
testSubscriptionId=''

az group create -n $testVMRg -l $testVmRegion -o table
: ' 
To clean up
az group delete -n $sigRgName --no-wait -y
'
az vm create -g $testVmRg -n $testVmName \
    --image "/subscriptions/$testSubscriptionId/resourceGroups/$testVmRg/providers/Microsoft.Compute/galleries/$sigName/images/$imageDefinition" \
    --specialized \
    -o table

#----------------------------------
# 5. Share the image gallery
#----------------------------------
# One may share images across subscriptions using Role-Based Access Control (RBAC)

galleryId=$(az sig show -g $sigRgName --gallery-name $sigName --query id -o tsv)
userEmailAddress='no1@notthere.com'

az role assignment create \
   --role "Reader" \
   --assignee $userEmailAddress \
   --scope $galleryId

