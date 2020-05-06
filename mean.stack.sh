:'
az login
'
# CUSTOMIZATION
export region='southcentralus'
export freeTier='free'
export sharedTier='d1'
export githubSourceCodeURL="https://github.com/jsmith/myWebAppRepo"
export adminID='alice'

# DEPLOYMENT ROUTINE
export tag=$(date +%M%S)
export rgName='rg'$tag
export vmName='vm'$tag
export uImage='ubuntults'
export servicePlanName='plan'$tag
export webAppName='webapp'$tag
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
    --image $uImage --os-disk-name 'OsDisk'$tag \
    --generate-ssh-keys --authentication-type all \
    --nsg $nsgName \
    --public-ip-address-dns-name $vmName'-pip' --public-ip-address static \
    --query publicIpAddress \
    -o tsv
  )

# ssh $adminID@$vmPip


# Web App
:'
https://docs.microsoft.com/en-us/learn/modules/build-a-web-app-with-mean-on-a-linux-vm/6-create-a-basic-app

AngularJS is the predecessor to Angular. AngularJS is still commonly used for building web applications. While AngularJS is based on JavaScript, Angular is based on TypeScript, a programming language that makes it easier to write JavaScript programs.

'

sudo apt update && sudo apt upgrade -y &&
sudo apt-get install -y mongodb nodejs &&
sudo systemctl status mongodb &&
mogod --version &&
node -v
