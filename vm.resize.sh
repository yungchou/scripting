# Session Start
az login -o table

az account list -o table
subName="mySubscriptionName"
az account set -s $subName

#########################################################
:'
1.	Start a cloud shell Bash session in the subscription with which the vm has been deployed.
2.	Run the following statements in the cloud shell session and examine the results. 
    Validate the variables values fpr resources of your interests accordingly.
'
# variables
size=Standard_E20ds_v4
region=eastus2
rgName=FacilitySource_CBRE_PROD_RG
vmame=USAZFMP2PDB12
 
# size specifications
az vm list-skus -l $region --size $size
 
# vm sizes available for the region
az vm list-skus -l $region  --query [].size
 
# RESIZE OPTION FOR A SINGLE VM
az vm list-vm-resize-options -g $rgName -n $vmName -o table
 
# RESIZE OPTION FOR ALL VMS IN A RESOURCE GROUP
az vm list-vm-resize-options --ids $(az vm list -g $rgName --query "[].id" -o tsv)
 
# AVAILABLE RESOURCE USAGE IN A REGION
az vm list-usage -l $region -o table
 
# AVAILABLE RESOURCE USAGE FOR VMs
az vm list-usage -l $region -o table
 
