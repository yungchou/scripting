#
az login -o table
az account list -o table

#---------------
# CUSTOMIZATION
#---------------
# Subscription context
subId='????'
az account set --subscription $subId
az account show --subscription $subId -query tenantId

 
# Export the JSON file of a source VM
# https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-cli#export-resource-groups-to-templates

echo "Enter the Resource Group name:" &&
read rgName &&

# Source objects
vmName="??"
rgName="??"

az group export --name $rgName


Get-AzureRmVM -ResourceGroupName $rgName -Name $vmName | ConvertTo-Json -depth 100 | Out-file -FilePath c:\temp\$vmname.json
 
# Stop deallocate the source VM;
Stop-AzureRmVM -ResourceGroupName $rgName -Name $vmName
 
# Remove the source VM
Remove-AzureRmVM -ResourceGroupName $rgName -Name $vmName
 
 