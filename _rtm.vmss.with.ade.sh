# vmss with data disks
# https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/scripts/cli-sample-create-simple-scale-set?toc=/cli/azure/toc.json#sample-script

# Session Start
az login -o table
az account list -o table

# CUSTOMIZATION
prefix='da'

# Session Tag
tag=$prefix$(date +%M%S)

rgName=$tag
region='southcentralus'

vmssName=$tag"vmss"
adminID='alice'

#vmImage='ubuntults'
vmImage='win2016datacenter'
#vmImage='win2019datacenter'
vmSize='Standard_B2ms'

az group create -n $rgName -l $region -o table
# az group delete -n $rgName --no-wait --yes 

az vmss create -n $vmssName -g $rgName -l $region  \
  --public-ip-address $tag'vmss' \
  --image $vmImage --vm-sku $vmSize --instance-count 2 \
  --data-disk-sizes-gb 4 \
  --admin-username $adminID \
  --disable-overprovision $true \
  --upgrade-policy Automatic \
  --scale-in-policy OldestVM \
  --no-wait

# --data-disk-encryption-sets \
# --customer-data cloud_init.yaml
# --validate
#  --eviction-policy Delete \
#  --authentication-type All --generate-ssh-keys \

az vmss list-instance -g $rgName -n $vmssName -o table
az vmss get-instance-view -g $rgName -n $vmssName

#-----------------
kvName=$tag'-kv'
sseKeyName=$tag'-sse-key'

az keyvault create -n $kvName -g $rgName -l $region -o table \
  --enabled-for-disk-encryption true \
  --enabled-for-deployment true \
  --enabled-for-template-deployment true \
  --sku standard  # premium, standard(default)

az keyvault key create --vault-name $kvName -n $sseKeyName \
  --ops wrapKey unwrapKey

# BEK
az vmss encryption enable -g $rgName -n $vmssName \
  --volume-type ALL \
  --disk-encryption-keyvault $kvName \
  --no-wait
  
# KEK|BEK
#  --key-encryption-key $sseKeyName
#  --key-encryption-keyvault # If missing, CLI will use `--disk-encryption-keyvault`.

az vmss encryption show -n $vmssName -g $rgName 
#--query encryption.type -o tsv

"disks": [
    {
      "encryptionSettings": [
        {
          "diskEncryptionKey": {
            "secretUrl": "https://<kvName>.vault.azure.net/secrets/E821F1...",
            "sourceVault": {
              "id": "/subscriptions/.../resourceGroups/dada/providers/Microsoft.KeyVault/vaults/<kvName>"
            }
          },
          "enabled": true,
          "keyEncryptionKey": null
        }
      ],
      "name": "vm1_OsDisk_1_4ea8ee92f0aa4824b25c55147a8bd3e3",
      "statuses": [
        {
          "code": "EncryptionState/encrypted",
          "displayStatus": "Encryption is enabled on disk",
          "level": "Info",
          "message": null,
          "time": null
        }
      ]
    }
  ]