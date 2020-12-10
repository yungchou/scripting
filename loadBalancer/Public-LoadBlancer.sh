:'
Load balancing settings
-----------------------

- Application Gateway is an HTTP/HTTPS web traffic load balancer with URL-based routing, SSL termination, session persistence, and web application firewall. Learn more about Application Gateway (must pre-exist before vmss creation), https://docs.microsoft.com/en-us/azure/application-gateway/overview

- Azure Load Balancer supports all TCP/UDP network traffic, port-forwarding, and outbound flows. Learn more about Azure Load Balancer, https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-overview

https://docs.microsoft.com/en-us/azure/load-balancer/quickstart-load-balancer-standard-public-cli?tabs=option-1-create-load-balancer-standard
'

#---------------------
# Session and context
#---------------------
az login -o table

az account list -o table
subId='????'
az account set --subscription $subId

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

#----------------------------
# CONFIGURE VIRTUIAL NETWORK
#----------------------------

# Create a virtual network
az network vnet create \
  --resource-group CreatePubLBQS-rg \
  --location eastus \
  --name myVNet \
  --address-prefixes 10.1.0.0/16 \
  --subnet-name myBackendSubnet \
  --subnet-prefixes 10.1.0.0/24

# Create a public IP address
az network public-ip create \
  --resource-group CreatePubLBQS-rg \
  --name myBastionIP \
  --sku Standard

# Create a bastion subnet
az network vnet subnet create \
  --resource-group CreatePubLBQS-rg \
  --name AzureBastionSubnet \
  --vnet-name myVNet \
  --address-prefixes 10.1.1.0/24

# Create bastion host
az network bastion create \
  --resource-group CreatePubLBQS-rg \
  --name myBastionHost \
  --public-ip-address myBastionIP \
  --vnet-name myVNet \
  --location eastus

# Create a network security group
az network nsg create \
  --resource-group CreatePubLBQS-rg \
  --name myNSG

# Create a network security group rule
az network nsg rule create \
  --resource-group CreatePubLBQS-rg \
  --nsg-name myNSG \
  --name myNSGRuleHTTP \
  --protocol '*' \
  --direction inbound \
  --source-address-prefix '*' \
  --source-port-range '*' \
  --destination-address-prefix '*' \
  --destination-port-range 80 \
  --access allow \
  --priority 200

#-----------------------
# CREATE BACKEND SERVER
#-----------------------

# Create network interfaces for the virtual machines
array=(myNicVM1 myNicVM2 myNicVM3)
for vmnic in "${array[@]}"
do
  az network nic create \
    --resource-group CreatePubLBQS-rg \
    --name $vmnic \
    --vnet-name myVNet \
    --subnet myBackEndSubnet \
    --network-security-group myNSG
  
  az vm create \
    --resource-group CreatePubLBQS-rg \
    --name myVM1 \
    --nics myNicVM1 \
    --image win2019datacenter \
    --admin-username azureuser \
    --zone 1 \ # loo through to create 3 zones
    --no-wait
done

#-----------------------------------
# CREAT AND CONFITURE LOAD BALANCER
#-----------------------------------
:'
A frontend IP pool that receives the incoming network traffic on the load balancer.
A backend IP pool where the frontend pool sends the load balanced network traffic.
A health probe that determines health of the backend VM instances.
A load balancer rule that defines how traffic is distributed to the VMs.
'

# Create a public IP address
az network public-ip create \
  --resource-group CreatePubLBQS-rg \
  --name myPublicIP \
  --sku Standard
 # --zone 1  # If zone specific

# Create a load balancer
az network lb create \
  --resource-group CreatePubLBQS-rg \
  --name myLoadBalancer \
  --sku Standard \
  --public-ip-address myPublicIP \
  --frontend-ip-name myFrontEnd \
  --backend-pool-name myBackEndPool

# Create the health probe
az network lb probe create \
  --resource-group CreatePubLBQS-rg \
  --lb-name myLoadBalancer \
  --name myHealthProbe \
  --protocol tcp \
  --port 80

# Create the load balancer rule
az network lb rule create \
  --resource-group CreatePubLBQS-rg \
  --lb-name myLoadBalancer \
  --name myHTTPRule \
  --protocol tcp \
  --frontend-port 80 \
  --backend-port 80 \
  --frontend-ip-name myFrontEnd \
  --backend-pool-name myBackEndPool \
  --probe-name myHealthProbe \
  --disable-outbound-snat true \
  --idle-timeout 15 \
  --enable-tcp-reset true
  
# Add virtual machines to load balancer backend pool
array=(myNicVM1 myNicVM2 myNicVM3)
for vmnic in "${array[@]}"
do
  az network nic ip-config address-pool add \
    --address-pool myBackendPool \
    --ip-config-name ipconfig1 \
    --nic-name $vmnic \
    --resource-group CreatePubLBQS-rg \
    --lb-name myLoadBalancer
done

# Create outbound rule configuration
az network public-ip create \
  --resource-group CreatePubLBQS-rg \
  --name myPublicIPOutbound \
  --sku Standard
#  --zone 1   # If zone specific

# Create outbound frontend IP configuration
az network lb frontend-ip create \
  --resource-group CreatePubLBQS-rg \
  --name myFrontEndOutbound \
  --lb-name myLoadBalancer \
  --public-ip-address myPublicIPOutbound

# Create outbound pool
az network lb address-pool create \
  --resource-group CreatePubLBQS-rg \
  --lb-name myLoadBalancer \
  --name myBackendPoolOutbound

# Create outbound rule
az network lb outbound-rule create \
  --resource-group CreatePubLBQS-rg \
  --lb-name myLoadBalancer \
  --name myOutboundRule \
  --frontend-ip-configs myFrontEndOutbound \
  --protocol All \
  --idle-timeout 15 \
  --outbound-ports 10000 \
  --address-pool myBackEndPoolOutbound

# Add virtual machines to outbound pool
array=(myNicVM1 myNicVM2 myNicVM3)
for vmnic in "${array[@]}"
do
  az network nic ip-config address-pool add \
    --address-pool myBackendPoolOutbound \
    --ip-config-name ipconfig1 \
    --nic-name $vmnic \
    --resource-group CreatePubLBQS-rg \
    --lb-name myLoadBalancer
done

# Install IIS
array=(myVM1 myVM2 myVM3)
  for vm in "${array[@]}"
  do
    az vm extension set \
      --publisher Microsoft.Compute \
      --version 1.8 \
      --name CustomScriptExtension \
      --vm-name $vm \
      --resource-group CreatePubLBQS-rg \
      --settings '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"}'
done

# Test the load balancer
az network public-ip show \
  --resource-group CreatePubLBQS-rg \
  --name myPublicIP \
  --query ipAddress \
  --output tsv



