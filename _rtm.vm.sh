# CUSTOMIZATION

export region='southcentralus'
export freeTier='free'
export sharedTier='d1'
export githubSourceCodeURL="https://github.com/jsmith/myWebAppRepo"
export adminID='alice'

# DEPLOYMENT ROUTINE
#az login

export tag=$(date +%M%S)
export rgName=$tag
export vmName=$tag'-vm'
export vmImage='ubuntults'
export servicePlanName=$tag'-plan'
export webAppName=$tag'-webapp'
export priority=100

az group create -n $rgName -l $region -o table
: '
az group delete -n $rgName --no-wait -y

az group list --query "[?name == '$rgName']"
az configure --defaults group=$rgName

# -f offer, -s sku, -p publisher
az vm image list -l southcentralus --all -p MicrosoftWindowsServer -o table # takes minutes
az vm list-sizes -l $region --location westeurope -o table
'
# 
nsgName='nsg'$tag
ruleName='rule'$tag 

az network nsg create -g $rgName -n $nsgName

az network nsg rule create \
  -g $rgName --nsg-name $nsgName -n $ruleName --priority $priority \
  --protocol Tcp --access Allow \
  --destination-port-ranges 22 3389 80 443 \
  --description '*** FOR TESTING ONLY, NOT FOR PRODUCTION ***' \
  -o table

# CREATE VM AND RETURN THE IP
vmPip=$(
  az vm create -g $rgName -n $vmName -l $region  --admin-username $adminID \
    --image $vmImage --os-disk-name $vmName'-OsDisk' \
    --nsg $nsgName \
    --public-ip-address-dns-name $vmName'-pip' --public-ip-address static \
    --query publicIpAddress \
    -o tsv
  ); echo "The vm, $vmName, deployed with the IP, $vmPip"

# For Linux vm,
#  --generate-ssh-keys --authentication-type all \

# ssh $adminID@$vmPip
