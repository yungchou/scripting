# Quickstart: Create Azure Resource Manager templates with Visual Studio Code
# https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/quickstart-create-templates-use-visual-studio-code?tabs=CLI

rgName='??'
region='southcentralus'
az group create -n $rgName -l $region - o table

az group deployment create -n $rgname'-deployment' -g $rgName \
  --template-file storage.json \
  --parameters storageAccountType=Standard_GRS

 # Remote template
 # --template-uri "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-storage-account-create/azuredeploy.json" \ 

 