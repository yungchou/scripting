<<Block_comment
#-------------------------------------------------------------------
# Sign in with Azure CLI
# https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli
#-------------------------------------------------------------------
az login -o table
az login -u <username> -p <password>
read -sp "Azure password: " AZ_PASS && echo && az login -u <username> -p $AZ_PASS

#------------------
# Set subscription
#------------------
az account list -o table
subId='????'
az account set --subscription $subId
az account show --subscription $subId -query tenantId
Block_comment

#---------------
# CUSTOMIZATION
#---------------
prefix='da'
tag=$prefix$(date +%M%S)

region='southcentralus'

adminUser='testuser'
adminPwd='4testingonly!'

#vmImage='ubuntults'
#vmImage='win2016datacenter'
vmImage='win2019datacenter'

<<Block_comment
#-------------------
# Image infomration
#-------------------
az vm image list --all -f elasticsearch -o table
az vm image list -s VS-2017 --all -o table
az vm list-sizes --location westeurope -o table
Block_comment

vmSize='Standard_B2ms' 
#vmSize='Standard_DS3_V2'

$openPorts='80,443,22,3890'
$nsgPriority=100

#----------------
# Resource Group
#----------------
rgName=$tag
az group create -n $rgName --location $region -o table

#-----------
# Simple VM
#-----------
$vmName=$rgName'vm'

echo "VM, $vmName, created with the public IP, $(
  # Vm deployment routine
  az vm create -g $rgName -n $rgName'vm' \
  --image $vmImage --size $vmSize \
  --admin-username $adminUser --admin-password $adminPwd \
  --use-unmanaged-disk \
  --storage-sku Standard_LRS \
  --query publicIpAddress \
  -o tsv
)"

# query: https://docs.microsoft.com/en-us/cli/azure/query-azure-cli

az vm show -g $rgName -n $vmName -o table

# List out everything created for the resoruce group
az resource list -g $ResourceGroupName -o table

# Open ports
az vm open-port -g $rgName -n $vmName \
  --nsg-name $($vmName+'nsg'+$nsgPriority) \
  --port $openPorts \
  -o table

# CustomScriptExtension
# Log: "C:\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension”
az vm extension set -g $rgName --vm-name $vmName \
  -name CustomScriptExtension \
  --publisher Microsoft.Compute \
  --settings '{"commandToExecute":"cd\; mkdir byCustomScriptExtension"}'

<<Block_comment
  --settings '{
    "fileUris":["https://my-assets.blob.core.windows.net/public/SetupSimpleSite.ps1"],"commandToExecute":"powershell.exe -ExecutionPolicy Unrestricted -file SetupSimpleSite.ps1"
    }'
Block_comment

# VM Public IP
az vm show -d -g $rgName -n $vmName --query publicIps -o tsv

<<Block_comment
az group delete -n $rgName --no-wait --yes

az vm list -g $rgName -o table -d
az vm show -d -g $rgName -n $vmName -o table --query "powerState" 
az vm deallocate -n $vmName -g $rgName --no-wait --yes

Block_comment


