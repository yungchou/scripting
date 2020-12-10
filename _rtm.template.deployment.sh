Tutorial: Create and deploy your first ARM template
https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-tutorial-create-first-template?tabs=azure-powershell

#---------------
# CUSTOMIZATION
#---------------
prefix='da'
region='southcentralus'

#---------
# SESSION 
#---------
tag=$prefix$(date +%M%S)
echo "Session tag = $tag"

#--------------------------
# 1. Create resource group
#--------------------------
rgName=$tag
az group create -n $rgName --location $region -o table

:'To clean up
az group delete -g $rgName -y --no-wait
'
#--------------------
# 2. Deploy template
#--------------------
templateFile="{provide-the-path-to-the-template-file}"
deploymentName=$rgName

az deployment group create -n $deploymentName -g $rgName -o table \
  --template-file $templateFile
  --verbose
