# The test command checks file types and compares values.


# CUSTOMIZATION
tag='yc'
region='southcentralus'

# Session Tag
tag+=$(date +%M%S)

# Resource Group
rgName=$tag'rg'

az group create -n $rgName --location $region -o table

: '
az group delete -n $rgName --no-wait -y
az configure --defaults group=$rgName
'
