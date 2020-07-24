#  https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/4_Creating_a_Custom_Linux_Image_to_VHD

#-------------------------
# Step 1 : Enable Prereqs
#-------------------------
# Instead of checking if already registered, 
# simply register all required providers
# 
az feature register --namespace Microsoft.VirtualMachineImages \
  --name VirtualMachineTemplatePreview -o table
az provider register -n Microsoft.Storage
az provider register -n Microsoft.Compute
az provider register -n Microsoft.KeyVault

:'
# Check provider registeration status
az provider show -n Microsoft.VirtualMachineImages | grep registrationState
az provider show -n Microsoft.Storage | grep registrationState
az provider show -n Microsoft.Compute | grep registrationState
az provider show -n Microsoft.KeyVault | grep registrationState
'

# Set Permissions & Create Resource Group for Image Builder Images

# set your environment variables here!!!!
# https://github.com/danielsollondon/azvmimagebuilder/tree/master/solutions/4_Using_ENV_Variables

# destination image resource group
imgRgName=aibvhd

# location (see possible locations in main docs)
region=WestUS2

# your subscription
# get the current subID : 'az account show | grep id'
subId=$(az account show | grep id | tr -d '",' | cut -c7-)

# Image Template Name
imgTemplateName=helloImageTemplateVHD01

# image distribution metadata reference name
runOutputName=aibCustomVhd01ro

# create resource group
az group create -n $imgRgName -l $region -o table
:'
az group delete -n $imgRgName --AsJob
'
#------------------------------------
# Step 2 : Modify HelloImage Example
#------------------------------------
# download the example and configure it with your vars
baseTemplate='https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/quickquickstarts/4_Creating_a_Custom_Linux_Image_to_VHD/helloImageTemplateVHD.json' 
customTemplate='helloImageTemplateVHD.json'

curl $baseTemplate -o $customTemplate

sed -i -e "s/<subId>/$subId/g" $customTemplate
sed -i -e "s/<rgName>/$imgRgName/g" $customTemplate
sed -i -e "s/<region>/$region/g" $customTemplate
sed -i -e "s/<runOutputName>/$runOutputName/g" $customTemplate

#---------------------------
# Step 3 : Create the Image
#---------------------------
# submit the image confiuration to the VM Image Builder Service

az resource create \
    --resource-group $imgRgName \
    --properties @$customTemplate \
    --is-full-object \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n $imgTemplateName

# start the image build

az resource invoke-action \
     --resource-group $imgRgName \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     -n $imgTemplateName \
     --action Run 

# wait approx 15mins

#---------------------------------
# Step 4 : Get the URL to the VHD
#---------------------------------
az resource show \
    --ids "/subscriptions/$subId/resourcegroups/$imgRgName/providers/Microsoft.VirtualMachineImages/imageTemplates/$imgTemplateName/runOutputs/$runOutputName"  \
    --api-version=2019-05-01-preview | grep artifactUri
:'
Note!! Once the VHD has been created, copy it to an alternative location, as soon as possible. The VHD is stored in a storage account in the temporary Resource Group created when the Image Template is submitted to the AIB service. If you delete the Image Template, then you will loose this VHD.
"
#----------
# Clean Up
#----------
az resource delete \
    --resource-group $imgRgName \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n helloImageTemplate01

az group delete -n $imgRgName --AsJob

