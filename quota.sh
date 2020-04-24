# az commands
# https://docs.microsoft.com/en-us/cli/azure/reference-index?view=azure-cli-latest

# QUOTA SNIPPETS

az login -o table

rgName='zulu-vm'

# Each resource group is limited to 800 deployments in its deployment history.
# current coutn of deployment history
az deployment group list -g $rgName --query "length(@)"

# delete a deployment
az deployment group delete -g $rgName --name deploymentName

# delete all deployments older than 5 days
startdate=$(date +%F -d "-5days")
deployments=$(az deployment group list -g $rgName --query "[?properties.timestamp<'$startdate'].name" --output tsv)

for deployment in $deployments
do
  az deployment group delete -g $rgName --name $deployment
done

az logout

