:'
How to upgrade ADE extension on Win/Linux VM and VMSS
https://gist.github.com/emmajdong/d3557f8f87a57afcab9026b150161da8

ADE with AAD, i.e. Dual Pass, NO ACTION is required

Extension versions impacted:
Windows: Version 2.2.0.0 to Version 2.2.0.34
Linux: Version 1.1.0.0 to Version 1.1.0.51

Once updated, the ADE extension should be:
Windows: Version 2.2.0.35 and greater
Linux: Version 1.1.0.52 and greater
'
#----
# VM
#----
vmRgName='??'
vmName='??'

# Current version
az vm extension list -g $vmRgName --vm-name $vmName -o table

#------
# VMSS
#------
vmssRgName='??'
vmssName='??'

# Verify the current version
az vmss extension list -g $vmssRgName --vmss-name $vmssName -o table 

# show the vmss upgrade policy here

# Restart vmss instance based on the upgrade policy

az vmss update-instances --instance-ids * -n $vmssName -g $vmssRgName -o table --Verbose

# Verify the current version
az vmss extension list -g $vmssRgName --vmss-name $vmssName -o table 
:'
Once updated, the ADE extension should be:
Windows: Version 2.2.0.35 and greater
Linux: Version 1.1.0.52 and greater
'
