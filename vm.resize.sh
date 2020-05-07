# Session Start
az login
az account list -o table

#########################################################

# CUSTOMIZATION
initial='yc'

# Session Tag
tag=$initial$(date +%M%S)

# Resource Group
rgName=$tag"rg"
region='southcentralus'

az group create -n $rgName --location $region -o table


az vm list-vm-resize-options \
[--ids]
[--name]
[--only-show-errors]
[--resource-group]
[--subscription]

