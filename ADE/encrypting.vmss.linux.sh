rgName='??'
locaiton='??'

az group create -n $rgName -l $location 

az group deployment create -g $rgName \
  --template-uri https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-encrypt-vmss-linux-jumpbox/azuredeploy.json



  