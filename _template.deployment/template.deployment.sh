:'
https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-cli
'
rgName='??'
region='southcentralus'
templateFilePath='??'

#------------------
# Deployment scope
#------------------
# Deploy to a resource group
az deployment group create -g $rgName --template-file $templateFilePath
# Deploy to a subscription
az deployment sub create -l $region --template-file $templateFilePath
# Deploy to a managed group
az deployment mg create -l $region --template-file $templateFilePath
# Deploy to a tenant
az deployment tenant create -l $region --template-file $templateFilePath

# Deploy a local template
az deployment group create \
  --name 'deployment'$(date +%M%S) \
  --resource-group $rgName \
  --template-file $templateFilePath \
  --parameters storageAccountType=Standard_LRS

# Deploy a remote template
az deployment group create \
  --name ExampleDeployment \
  --resource-group ExampleGroup \
  --template-uri "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-storage-account-create/azuredeploy.json" \
  --parameters storageAccountType=Standard_GRS
  
