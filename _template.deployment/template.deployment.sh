:'
https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-cli

AZ CLI random number generator: $RANDOM
'
prefix='da'

# Session
session=$prefix$(date +%M%S)

rgName=$session
region='southcentralus'

# Storage Account Type
saType='Standard_LRS'

#------------------
# Deployment scope
#------------------
# Deploy to a resource group
az deployment group create -n $session -g $rgName \
  -f 't.json' \
  --verbose -o table

  -p storageAccountType=$saType \

:'
# Remote template (URI)
  -u "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-storage-account-create/azuredeploy.json" 

  --subscription subID
'

# Minimal
#az deployment group create -g $rgName --template-file $templateFilePath

# Deploy to a subscription
az deployment sub create -l $region --template-file $templateFilePath
# Deploy to a managed group
az deployment mg create -l $region --template-file $templateFilePath
# Deploy to a tenant
az deployment tenant create -l $region --template-file $templateFilePath



  
