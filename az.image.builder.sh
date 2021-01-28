:'
https://docs.microsoft.com/en-us/azure/virtual-machines/linux/image-builder
'
# For 1st-time usage as a preview feature, as applicable only
az feature register --namespace Microsoft.VirtualMachineImages --name VirtualMachineTemplatePreview

az provider register -n Microsoft.VirtualMachineImages
az provider register -n Microsoft.Compute
az provider register -n Microsoft.KeyVault
az provider register -n Microsoft.Storage

# check registeration status
az feature show --namespace Microsoft.VirtualMachineImages --name VirtualMachineTemplatePreview -o json | grep state

az provider show -n Microsoft.VirtualMachineImages -o json | grep registrationState
az provider show -n Microsoft.KeyVault -o json | grep registrationState
az provider show -n Microsoft.Compute -o json | grep registrationState
az provider show -n Microsoft.Storage -o json | grep registrationState

######################

sigResourceGroup=ibLinuxGalleryRG
location=westus2
additionalregion=eastus  # Additional region to replicate the image to
sigName=myIbGallery
imageDefName=myIbImageDef
runOutputName=aibLinuxSIG   # image distribution metadata reference name

subscriptionID=<Subscription ID>

az group create -n $sigResourceGroup -l $location

:'
###############################################################
Image Builder will use the user-identity provided to inject 
the image into the Azure Shared Image Gallery (SIG)
'
# create user assigned identity for image builder to access 
# the storage account where the script is located
session=$(date +'%M%S')
identityName="aibBuiUserId$session"
az identity create -g $sigResourceGroup -n $identityName

# get identity id
imgBuilderCliId=$(az identity show -g $sigResourceGroup -n $identityName -o json | grep "clientId" | cut -c16- | tr -d '",')

# Build the user identity URI, needed for the template
imgBuilderId=/subscriptions/$subscriptionID/resourcegroups/$sigResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$identityName

# Download an Azure role definition template, and update the template with the parameters specified earlier.
curl https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json -o aibRoleImageCreation.json

imageRoleDefName="Azure Image Builder Image Def$session"

# update the definition
sed -i -e "s/<subscriptionID>/$subscriptionID/g" aibRoleImageCreation.json
sed -i -e "s/<rgName>/$sigResourceGroup/g" aibRoleImageCreation.json
sed -i -e "s/Azure Image Builder Service Image Creation Role/$imageRoleDefName/g" aibRoleImageCreation.json

# create role definitions
az role definition create --role-definition ./aibRoleImageCreation.json

# grant role definition to the user assigned identity
az role assignment create \
    --assignee $imgBuilderCliId \
    --role "$imageRoleDefName" \
    --scope /subscriptions/$subscriptionID/resourceGroups/$sigResourceGroup

# continue from 
# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/image-builder#create-an-image-definition-and-gallery

