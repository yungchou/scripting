# Quickstart: Create Azure Resource Manager templates with Visual Studio Code
# https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/quickstart-create-template-specs?tabs=azure-cli

# Tutorial: Create and deploy your first ARM template
# https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-tutorial-create-first-template?tabs=azure-powershell

# Quickstart: Create and deploy template spec 
# https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/quickstart-create-template-specs?tabs=azure-powershell#deploy-template-spec

# 1. As needed, create a resource group to contain the new storage account.
az group create -n storageRG -l westus2

# 2. Get the resource ID of the template spec.
id = $(az ts show -n storageSpec -g templateSpecRG --version "1.0" --query "id")

# 3. Deploy the template spec.
az deployment group create \
  -g storageRG \
  --template-spec $id

# 4. Provide parameters exactly as you would for an ARM template. Redeploy the template spec with a parameter for the storage account type.
az deployment group create \
  -g storageRG \
  --template-spec $id \
  --parameters storageAccountType='Standard_GRS'


