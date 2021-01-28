:'
Deploy to dedicated hosts using the Azure CLI
https://docs.microsoft.com/en-us/azure/virtual-machines/linux/dedicated-hosts-cli

Host Group high availability option

1. Span across multiple availability zones. In this case, you are required to have a host group in each of the zones you wish to use.

2. Span across multiple fault domains which are mapped to physical racks.

In either case, you are need to provide the fault domain count for a host group. If you do not want to span fault domains in your group, use a fault domain count of 1.


VMSS TO DEDICATED HOST GROUP
----------------------------
https://docs.microsoft.com/en-us/azure/virtual-machines/dedicated-hosts#virtual-machine-scale-set-support
When creating a virtual machine scale set you can specify an existing host group to have all of the VM instances created on dedicated hosts.

Requirements
------------
- Automatic VM placement needs to be enabled.
- The availability setting of your host group should match your scale set.
  - A regional host group (created without specifying an availability zone) should be used for regional scale sets.
  - The host group and the scale set must be using the same availability zone.
  - The fault domain count for the host group level should match the fault domain count for your scale set. The Azure portal lets you specify max spreading for your scale set, which sets the fault domain count of 1.
- Dedicated hosts should be created first, with sufficient capacity, and the same settings for scale set zones and fault domains.
- The supported VM sizes for your dedicated hosts should match the one used for your scale set.

Not all scale-set orchestration and optimizations settings are supported by dedicated hosts. Apply the following settings to your scale set:

- Disable overprovisioning.
- Use the ScaleSetVM orchestration mode
- Do not use proximity placement groups for co-location

Quotas
------
- Dedicated host vCPU quota. The default quota limit is 3000 vCPUs, per region.
- VM size family quota. For example, a Pay-as-you-go subscription may only have a quota of 10 vCPUs available for the Dsv3 size series, in the East US region. To deploy a Dsv3 dedicated host, you would need to request a quota increase to at least 64 vCPUs before you can deploy the dedicated host.

Once a Dedicated host is provisoned, you can not change the size or type. If you need a different size of type, you will need to create a new host.

'
#---------------------
# Session and context
#---------------------
az login -o table

az account list -o table
subId='????'
az account set --subscription $subId

az account show --subscription $subId -query tenantId
#---------------
# CUSTOMIZATION
#---------------
prefix='da'
tag=$prefix$(date +%M%S)

adminID='alice'
region='southcentralus'

#vmImage='ubuntults'
vmImage='win2016datacenter'
#vmImage='win2019datacenter'

vmSize='Standard_B2ms' 
#vmSize='Standard_DS3_V2'

#----------------
# Resource Group
#----------------
rgName=$tag
az group create -n $rgName --location $region -o table
# az group delete -n $rgName --no-wait --yes 

# List available SKUs in a region
az vm list-skus -l eastus2  -r hostGroups/hosts  -o table

# Create a host group
az vm host group create \
  --name myHostGroup \
  -g myDHResourceGroup \
  --platform-fault-domain-count 2 \
:'
  -z 1  # zone specific 
  --automatic-placement true # VMs and scale set instances aut-placed on hosts within a host group

https://docs.microsoft.com/en-us/azure/virtual-machines/dedicated-hosts#manual-vs-automatic-placement
'

# Create a host
az vm host create \
  --host-group myHostGroup \
  --name myHost \
  --sku DSv3-Type1 \
  --platform-fault-domain 1 \
  -g myDHResourceGroup

# Create/deploy a VM
az vm create \
  -n myVM \
  --image debian \
  --host-group myHostGroup \
  --generate-ssh-keys \
  --size Standard_D4s_v3 \
  -g myDHResourceGroup \
  --zone 1

# If a host which does not have enough resources, 
# a virtual machine will be created in a FAILED state.

# Create/deloy a VMSS
az vmss create \
  --resource-group myResourceGroup \
  --name myScaleSet \
  --image UbuntuLTS \
  --upgrade-policy-mode automatic \
  --admin-username azureuser \
  --host-group myHostGroup \
  --generate-ssh-keys \
  --size Standard_D4s_v3 \
  -g myDHResourceGroup \
  --zone 1

# Check host status
az vm host get-instance-view \
  -g myDHResourceGroup \
  --host-group myHostGroup \
  --name myHost

# Export as a template
sourceRgName='??'
templateName=$sourceRgName'-template.json'
az group export -n $sourceRgName > $templateName
:'
This command creates $tempalteName file in the current directory. 
When creating an environment with this template, interactively 
enter all the resource names. Or populating these names in 
the template file by adding the parameter
--include-parameter-default-value  
to the az group export command. Edit the JSON template or create 
a parameters.json file that specifies the resource names.
'
targetRgName='??'
deploymentName=$templateName'-deployment-'$(date +%M%S)
az deployment group create -n $deploymentName -g $targetRgName \
  --template-file $templateName \
  --no-wait

# CLEAN UP
vmName='??'
vmRgName='??'
az vm delete -n $vmName -g $vmRgName

hostName='??'
hostGroupName='??'
hostRgName='??'
az vm host delete -n $hostName -g $hostRgName --host-group $hostGroupName
az vm host group delete -g $hostRgName --host-group $hostGroupName
az group delete -n $hostRgName
