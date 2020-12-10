#---------------------
# Session and context
#---------------------
az login -o table

az account list -o table
subId='????'
az account set --subscription $subId

az account show --subscription $subId -query tenantId
#---------------
# CUSTOMIZATION
#---------------
prefix='da'
tag=$prefix$(date +%M%S)

adminID='alice'
region='southcentralus'

#vmImage='ubuntults'
vmImage='win2016datacenter'
#vmImage='win2019datacenter'

vmSize='Standard_B2ms' 
#vmSize='Standard_DS3_V2'

#----------------
# Resource Group
#----------------
rgName=$tag
az group create -n $rgName --location $region -o table
# az group delete -n $rgName --no-wait --yes 


