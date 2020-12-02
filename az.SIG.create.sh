:'
Windows virtual machines in Azure
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/

Linux virtual machines in Azure
https://docs.microsoft.com/en-us/azure/virtual-machines/linux/

Shared Image Galleries overview
https://docs.microsoft.com/en-us/azure/virtual-machines/linux/shared-image-galleries

Create a Shared Image Gallery with the Azure CLI
https://docs.microsoft.com/en-us/azure/virtual-machines/shared-images-cli 
'
#---------
# CONTEXT
#---------
:' As needed
az login

az account list -o table
subName="mySubscriptionName"
az account set -s $subName
'
#---------------
# CUSTOMIZATION
#---------------
prefix='da'
region='southcentralus'

#--------

tag=$prefix$(date +%M%S)
echo "Session tag = $tag"

#----------------
# Resource Group
#----------------
rgName=$tag
az group create -n $rgName --location $region -o table

:'To clean up
az group delete -g $rgName -y --no-wait
'
###############################

# 1. CREATE SHAERD IMAGE GALLERY
sigName=$rgName'.SIG'
az sig create -g $rgName --gallery-name $sigName -o table

# 2. ASSIGN USER ACCESS
sigReaderEmailAddress='abc@def.com for azure rbac'
sigId=$(az sig show -g $rgName --gallery-name $sigName --query id -o tsv)
az role assignment create \
  --role "Reader" --scope sigId \
  --assignee $sigReaderEmailAddress \
  -o table

# 3. CREATE IMAGE VERSION

#---------------------------------------
# 3.1 Create an image version from a VM
#---------------------------------------
# https://docs.microsoft.com/en-us/azure/virtual-machines/image-version-vm-cli

# Get vm info
az vm list --output table

sourceVmRgName='??'
sourceVmName='??'
sourceVmId=$(az vm get-instance-view -g $sourceVmRgName -n $sourceVmName --query id -o tsv)
sourceVmOsType=$(az vm get-instance-view -g $sourceVmRgName -n $sourceVmName --query storageProfile.osDisk.osType -o tsv)

# Specify the image based on a speialized or generalized disk
sourceVmOsState='specialized'   
#sourceVmOsState='generalized'   

# Create image definition
source=$sourceVmName
sourceImgDef=$source'-ImgDef'
sourceImgPublisher=$source'-Publisher'
sourceImgOffer=$source'-ImgOffer'
sourceImgSku=$source'-Sku'

az sig image-definition create -g $rgName \
  --gallery-name $sigName \
  --gallery-image-definition $sourceImgDef \
  --publisher $sourceImgPublisher \
  --offer $sourceImgOffer \
  --sku $sourceImgSku \
  --os-type $sourceVmOsType \
  --os-state $sourceVmOsState \
  -o table

# The replication regions must include the region the source VM is located.
az sig image-version create -g $rgName \
  --gallery-name $sigName \
  --gallery-image-definition $sourceImgDef \
  --gallery-image-version 1.0.0 \
  --target-regions  "centralus" \
                    "southcentralus=1=standard_zrs" \
  --replica-count 2 \
  --managed-image $sourceVmId \
  -o table

# Verify the deployment
az image show -g $rgName -o table
az image list --query "[].[name, id]" -o tsv

# BEST TO USE A BATCH JOB SINCE IMAGE DEPLOYMENT TAKES AWHILE.

#--------------------------------------------------
# 3.2 Create an image version from a managed image
#--------------------------------------------------
# https://docs.microsoft.com/en-us/azure/virtual-machines/image-version-managed-image-cli

resourceGroup=myGalleryRG
gallery=myGallery

az sig list -o table
az sig show imageDef=myImageDef

az sig image-definition list -g da1020 --gallery-name da1020.SIG --query "[].[
  location,name,osState,osType,id,identifier.offer,identifier.publisher,identifier.sku
  ]"

imagePublisher=$imageDef'-publisher'
imageOffer=$imageDef'-offer'
imageSku=$imageDef'-sku'

$imageOsType='linux'

# Specify the image based on a speialized or generalized disk
imageOsState='specialized'   
#imageOsState='generalized'   

az sig image-definition create \
   -g $resourceGroup \
   --gallery-name $gallery \
   --gallery-image-definition $imageDef \
   --publisher $imagePublisher \
   --offer $imageOffer \
   --sku $imageSku \
   --os-type $imageOsType \
   --os-state $imageOsSate \
   -o table


