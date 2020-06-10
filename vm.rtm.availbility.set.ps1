
region='southcentralus'

az vm list-skus -l $region \
  --resource-type availabilitySets \
  -o Table \
  --query '[?name==`Aligned`].{Location:locationInfo[0].location, MaximumFaultDomainCount:capabilities[0].value}'

