:'
Create an Azure service principal with the Azure CLI
https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest

Azure Disk Encryption with Azure AD (dual pass, previous release)
https://docs.microsoft.com/en-us/azure/virtual-machines/windows/disk-encryption-overview-aad


'
#---------------
# CUSTOMIZATION
#---------------
prefix='da'
region='southcentralus'

#------------------
# Standard Routine
#------------------
# Session Tag
tag=$prefix$(date +%M%S)

#az extension list-available -o table

#----------------------------------------------
# Create a service principal for ADE Dual Pass
#----------------------------------------------
$rgName=$tag
spName=$tag'-spn'
#subId='mySubId'
kvName=$tag'-kv'
region='southcentralus'

# Create using a self-signed certificate, and store it within KeyVault
az ad sp create-for-rbac -n $spName --role contributor -o table \
  --keyvault $kvName --cert $spName'-cert' --create-cert
#  --scopes "/subscriptions/$subID/resourceGroups/$rgName" 

#spId=$(az disk-encryption-set show -n $desName -g $rgName --query [identity.principalId] -o tsv)
az keyvault set-policy -n $kvName -g $rgName --spn $spName \
  --key-permissions wrapkey unwrapkey get

#  --secret-permissions wrapkey unwrapkey get
#  --storage-permissions wrapkey unwrapkey get

az ad sp show --id $spName -o table

# Set the key vault access policy for the Azure AD app
# https://docs.microsoft.com/en-us/azure/virtual-machines/windows/disk-encryption-key-vault-aad#set-the-key-vault-access-policy-for-the-azure-ad-app

# Set Advanced Access Policies
az keyvault create -n $kvName -g $rgName -l $region -o table \
  --enabled-for-disk-encryption true \
  --enabled-for-deployment true \
  --enabled-for-template-deployment true \
  --sku standard  # premium, standard (default)

# Set Key Access Policy
 az keyvault set-policy -n $kvName --spn $spName \
  --key-permissions wrapKey --secret-permissions set

# If KEK
az keyvault key create --vault-name $kvName -n $tag'-ade-key' -o table \
  --kty RSA-HSM \
  --ops decrypt encrypt import sign unwrapKey verify wrapKey
