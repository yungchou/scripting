vmName='??'
rgName='??'

az vm show -n $vmName -g $rgName
az vm get-instance-view -n $vmName -g $rgName

