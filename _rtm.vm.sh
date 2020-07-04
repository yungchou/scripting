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
export uImage='ubuntults'
export servicePlanName=$tag'-plan'
export webAppName=$tag'-webapp'
export priority=100

az group create -n $rgName -l $region -o table
: '
az group delete -n $rgName --no-wait -y

az group list --query "[?name == '$rgName']"
az configure --defaults group=$rgName
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
    --image $uImage --os-disk-name $vmName'-OsDisk' \
    --nsg $nsgName \
    --public-ip-address-dns-name $vmName'-pip' --public-ip-address static \
    --query publicIpAddress \
    -o tsv
  ); echo "The vm, $vmName, deployed with the IP, $vmPip"

# For Linux vm,
#  --generate-ssh-keys --authentication-type all \

# ssh $adminID@$vmPip
