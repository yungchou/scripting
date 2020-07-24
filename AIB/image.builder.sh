# https://github.com/danielsollondon/azvmimagebuilder/tree/master/quickquickstarts/1a_Creating_a_Custom_Linux_Image_on_Existing_VNET

#-------------------------
# Step 1 : Enable Prereqs
#-------------------------
#Register for Image Builder/VM/Storage Features
az feature register --namespace Microsoft.VirtualMachineImages \
  --name VirtualMachineTemplatePreview -o table
az provider register -n Microsoft.Storage
az provider register -n Microsoft.Compute
az provider register -n Microsoft.KeyVault

# check you are registered for the providers
az provider show -n Microsoft.VirtualMachineImages | grep registrationState
az provider show -n Microsoft.Storage | grep registrationState
az provider show -n Microsoft.Compute | grep registrationState
az provider show -n Microsoft.KeyVault | grep registrationState

# Set Permissions & Create Resource Group for Image Builder Images
# set your environment variables here!!!!

# destination image resource group
imageResourceGroup=aibImage

# location (see possible locations in main docs)
location=WestUS2

# your subscription
# get the current subID : 'az account show | grep id'
subscriptionID=$(az account show | grep id | tr -d '",' | cut -c7-)

# name of the image to be created
imageName=aibU18

# image distribution metadata reference name
runOutputName=aibU18


# VNET properties (update to match your existing VNET, or leave as-is for demo)
# VNET name
vnetName=aibwest2
# subnet name
subnetName=one
# VNET resource group name
# NOTE! The VNET must always be in the same region as the AIB service region.
vnetRgName=aibwest2
# Existing Subnet NSG Name or the demo will create it
nsgName=aibNsg

# create resource group for image and image template resource
az group create -n $imageResourceGroup -l $location -o table

#------------------------------
# Step 2: Configure Networking
#------------------------------
# Note!! If you do not have an existing VNET\Subnet\NSG, follow these steps 
# to create a VNET\Subnet\NSG, these are required for the demo.

# Add NSG rule to allow the AIB deployed Azure Load Balancer to 
# communicate with the proxy VM
az network nsg rule create \
    --resource-group $imageResourceGroup \
    --nsg-name $nsgName \
    -n AzureImageBuilderNsgRule \
    --priority 400 \
    --source-address-prefixes AzureLoadBalancer \
    --destination-address-prefixes VirtualNetwork \
    --destination-port-ranges 60000-60001 --direction inbound \
    --access Allow --protocol Tcp \
    --description "Allow Image Builder Private Link Access to Proxy VM" \
    -o table

# This allows connectivity from the load balancer to the proxy VM, 
# specifically, 60001 is for Linux OS's, and 60000 for Windows OS's. 
# The proxy VM will connect to the build VM using port 22 for Linux OS's, 
# or 5986 for Windows OS's.

# Disable Private Service Policy on subnet
az network vnet subnet update \
  --name $subnetName \
  --resource-group $vnetRgName \
  --vnet-name $vnetName \
  --disable-private-link-service-network-policies true 

#--------------------------------------------------------------
# Step 2 : Modify the Example template and create role for AIB
#--------------------------------------------------------------
# download the example and configure it with your vars
curl https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/quickquickstarts/1a_Creating_a_Custom_Linux_Image_on_Existing_VNET/existingVNETLinux.json -o existingVNETLinux.json
curl https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleNetworking.json -o aibRoleNetworking.json
curl https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json -o aibRoleImageCreation.json

sed -i -e "s/<subscriptionID>/$subscriptionID/g" existingVNETLinux.json
sed -i -e "s/<rgName>/$imageResourceGroup/g" existingVNETLinux.json
sed -i -e "s/<region>/$location/g" existingVNETLinux.json
sed -i -e "s/<imageName>/$imageName/g" existingVNETLinux.json
sed -i -e "s/<runOutputName>/$runOutputName/g" existingVNETLinux.json

sed -i -e "s/<vnetName>/$vnetName/g" existingVNETLinux.json
sed -i -e "s/<subnetName>/$subnetName/g" existingVNETLinux.json
sed -i -e "s/<vnetRgName>/$vnetRgName/g" existingVNETLinux.json

sed -i -e "s/<subscriptionID>/$subscriptionID/g" aibRoleImageCreation.json
sed -i -e "s/<rgName>/$imageResourceGroup/g" aibRoleImageCreation.json

sed -i -e "s/<subscriptionID>/$subscriptionID/g" aibRoleNetworking.json
sed -i -e "s/<vnetRgName>/$vnetRgName/g" aibRoleNetworking.json

#---------------------------------------------------------
# Step 3: Create a user identify and assign permissions 
# for the resource group where the image will be created, 
# and permissions to join the existing VNET
#---------------------------------------------------------
# Create User-Assigned Managed Identity and Grant Permissions
# https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/qs-configure-cli-windows-vm#user-assigned-managed-identity

# create user assigned identity for image builder
idenityName=aibBuiUserId$(date +'%s')
az identity create -g $imageResourceGroup -n $idenityName

# get identity id
imgBuilderCliId=$(az identity show -g $imageResourceGroup -n $idenityName | grep "clientId" | cut -c16- | tr -d '",')

# get the user identity URI, needed for the template
imgBuilderId=/subscriptions/$subscriptionID/resourcegroups/$imageResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$idenityName

# update the template
sed -i -e "s%<imgBuilderId>%$imgBuilderId%g" existingVNETLinux.json

# make role name unique, to avoid clashes in the same AAD Domain
imageRoleDefName="Azure Image Builder Image Def"$(date +'%s')
netRoleDefName="Azure Image Builder Network Def"$(date +'%s')

# update the definitions
sed -i -e "s/Azure Image Builder Service Image Creation Role/$imageRoleDefName/g" aibRoleImageCreation.json
sed -i -e "s/Azure Image Builder Service Networking Role/$netRoleDefName/g" aibRoleNetworking.json

# create two roles, one gives the builder permissions to create an image, 
# the other allows it to connect the build VM and loadbalancer to your VNET.

# create role definitions
az role definition create --role-definition ./aibRoleImageCreation.json
az role definition create --role-definition ./aibRoleNetworking.json

# grant role definition to the user assigned identity
az role assignment create \
    --assignee $imgBuilderCliId \
    --role $imageRoleDefName \
    --scope /subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup

az role assignment create \
    --assignee $imgBuilderCliId \
    --role $netRoleDefName \
    --scope /subscriptions/$subscriptionID/resourceGroups/$vnetRgName

#---------------------------
# Step 3 : Create the Image
#---------------------------
# submit the image confiuration to the VM Image Builder Service

az resource create \
    --resource-group $imageResourceGroup \
    --properties @existingVNETLinux.json \
    --is-full-object \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n existingVNETLinuxTemplate01

# wait approx 1-3mins (validation, permissions etc.)

# start the image build

az resource invoke-action \
     --resource-group $imageResourceGroup \
     --resource-type  Microsoft.VirtualMachineImages/imageTemplates \
     -n existingVNETLinuxTemplate01 \
     --action Run 

# wait approx 15mins

#------------------------
# Step 4 : Create the VM
#------------------------
az vm create \
  --resource-group $imageResourceGroup \
  --name aibImgVm0001 \
  --admin-username aibuser \
  --image $imageName \
  --location $location \
  --generate-ssh-keys

# and login...

# ssh aibuser@<pubIp>

# You should see the image was customized with a Message of the Day 
# as soon as your SSH connection is established!

#----------
# Clean Up
#----------
az resource delete \
    --resource-group $imageResourceGroup \
    --resource-type Microsoft.VirtualMachineImages/imageTemplates \
    -n existingVNETLinuxTemplate01

# delete permissions asssignments, roles and identity
az role assignment delete \
    --assignee $imgBuilderCliId \
    --role $imageRoleDefName \
    --scope /subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup

az role assignment delete \
    --assignee $imgBuilderCliId \
    --role $netRoleDefName \
    --scope /subscriptions/$subscriptionID/resourceGroups/$vnetRgName


az role definition delete --name "$imageRoleDefName"
az role definition delete --name "$netRoleDefName"

az identity delete --ids $imgBuilderId

az group delete -n $imageResourceGroup
az group delete -n $vnetRgName

# delete VNET created
# BEWARE!!!!! In this example, you have either used an existing VNET 
# or created one for this example. 
# Do not delete your existing VNET. If you want to delete the VNET 
# Resource group used in this example '$vnetRgName', modify the above code.
