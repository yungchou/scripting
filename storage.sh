:'
Quickstart: Create, download, and list blobs with Azure CLI
https://docs.microsoft.com/en-us/azure/storage/blobs/storage-quickstart-blobs-cli
'
az storage account create \
    --name <storage-account> \
    --resource-group <resource-group> \
    --location <location> \
    --sku Standard_ZRS \
    --encryption-services blob

az storage container create \
    --account-name <storage-account> \
    --name <container> \
    --auth-mode login

az storage blob upload \
    --account-name <storage-account> \
    --container-name <container> \
    --name helloworld \
    --file helloworld \
    --auth-mode login

az storage blob list \
    --account-name <storage-account> \
    --container-name <container> \
    --output table \
    --auth-mode login

az storage blob download \
    --account-name <storage-account> \
    --container-name <container> \
    --name helloworld \
    --file ~/destination/path/for/file \
    --auth-mode login

# Data transfer with AzCopy
azcopy login
azcopy copy 'C:\myDirectory\myTextFile.txt' 'https://mystorageaccount.blob.core.windows.net/mycontainer/myTextFile.txt'

# Create a storage account and rotate its account access keys
#!/bin/bash

# Create a resource group
az group create --name myResourceGroup --location eastus

# Create a general-purpose standard storage account
az storage account create \
    --name mystorageaccount \
    --resource-group myResourceGroup \
    --location eastus \
    --sku Standard_RAGRS \
    --encryption blob

# List the storage account access keys
az storage account keys list \
    --resource-group myResourceGroup \
    --account-name mystorageaccount 

# Renew (rotate) the PRIMARY access key
az storage account keys renew \
    --resource-group myResourceGroup \
    --account-name mystorageaccount \
    --key primary

# Renew (rotate) the SECONDARY access key
az storage account keys renew \
    --resource-group myResourceGroup \
    --account-name mystorageaccount \
    --key secondary

# Clean up
az group delete --name myResourceGroup

