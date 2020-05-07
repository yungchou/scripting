# CUSTOMIZATION

export region='southcentralus'
export freeTier='free'
export sharedTier='d1'
export githubSourceCodeURL="https://github.com/jsmith/myWebAppRepo"

# DEPLOYMENT ROUTINE

export tag=$(date +%M%S)
export rgName='rg'$tag
export servicePlanName='plan'$tag
export webAppName='webapp'$tag

az group create -n $rgName -l $region -o table
: '
az group delete -n $rgName --no-wait -y

az group list --query "[?name == '$rgName']"
az configure --defaults group=$rgName
'

az appservice plan create 
  -g $rgName -n $servicePlanName -l $region \
  --sku $sharedTier \
  -o table

az webapp create \
  -g $rgName -n $webAppName \
  --plan $servicePlanName \
  -o table

curl $AZURE_WEB_APP.azurewebsites.net

# Deploy code from GitHub
az webapp deployment source config \
  -g $rgName -n $webAppName \
  --repo-url "https://github.com/Azure-Samples/php-docs-hello-world" \
  --branch master \
  --manual-integration \
  -o table

 curl $webAppName.azurewebsites.net

 
