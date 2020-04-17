# DEDICATED HOST
# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/dedicated-hosts-cli

#region [REQUIRED REFERENCE FILE]

$include="https://zulustore.blob.core.windows.net/public/yc.azure.iaas.v2.0.ps1"
try   { iex ($content=(New-Object Net.WebClient).DownloadString($include)) }
catch { write-host "Error while loading `n$include" -b black -f red; throw 'ERROR!'  }
Write-Host "Included the file, `n$include" -b black -f green

#$QSKfolder='c:\_azure.iaas'  # User-defined

#endregion


#region [required validation]

Connect-AzAccount

$azSubName = pick-one-item `
  -thisList (get-AzSubscription).Name `
  -itemDescription 'Subscription' `
  -gridView $true

$tag = "$prefix$(get-date -format 'HHmmss')"
write-host "`nSession ID = $tag" -b black -f green

#endregion

# CUSTOMIZATION
prefix='yc'

#region

tag="date +%H%M%S"
rgName=$prefix$tag
vmName="$rgName_vm"
region='southcentralus'
hgName="$rgName-hg"
hostName=$rgName-host
sku='DSv3-Type1'
# az vm list-sizes
vmSize='Standard_D4s_v3'
img='debian'

# RESOURCE GROUP
az group create -n $rgName --location $region -o table

# HOST GROUP
az vm host group create \
    -g $rgName \
    -n $hgName \
    -l $region \
    -c 2 \
    -o table

#    -z 1 \

# HOST
az vm host create \
   --host-group $hgName \
   -g $rgName \
   -n $hostName \
   -d 1 \
   --sku $sku  \
   --auto-replace \
   -o table

# HOST STATUS
az vm host get-instance-view \
   --host-group $hgName \
   -g $rgName \
   -n $hostName \
   -o table

# VM
az vm create \
   --host-group $hgName \
   --host $hostName \
    -g $rgName \
    -n $vmName \
    -l $region \
   --image $img \
   --authentication-type all \
   --generate-ssh-keys \
   --size $vmSize \
   -o table

   --zone 1 \

# EXPORT
fileName=$rgname'.json'
az group export -g $rgName > $fileName

# DEPLOYMENT
az group deployment create \ 
    -g $rgName \ 
    --template-file $fileName

# CLEAN UP
az vm delete -n $vmName -g $rgName
az vm host delete --host-group $hgName -g $rgName -n $hostName
az vm host group delete --host-group $hgName -g $rgName
az group delete -n $rgName --no-wait -y


#endregion

