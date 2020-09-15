:'
How to use Key Vault soft-delete with CLI
https://docs.microsoft.com/en-us/azure/key-vault/general/soft-delete-cli

az keyvault
https://docs.microsoft.com/en-us/cli/azure/keyvault?view=azure-cli-latest

Enabling "soft-delete" on a key vault is an irreversible action. Once the soft-delete property has been set to "true", it cannot be changed or removed.

'

az keyvault create --name ContosoVault --resource-group ContosoRG --enable-soft-delete true --location westus

az keyvault show --name ContosoVault
az keyvault update -n ContosoVault --enable-soft-delete true

# Deleting a soft-delete protected key vault
az keyvault delete --name ContosoVault
az keyvault list-deleted -o table
:'
- ID can be used to identify the resource when recovering or purging.
- Resource ID is the original resource ID of this vault. Since this key vault is now in a deleted state, no resource exists with that resource ID.
- Scheduled Purge Date is when the vault will be permanently deleted, if no action is taken. The default retention period, used to calculate the Scheduled Purge Date, is 90 days.
'
az keyvault recover --location westus --resource-group ContosoRG --name ContosoVault

az keyvault key delete --name ContosoFirstKey --vault-name ContosoVault
:'
With your key vault enabled for soft-delete, a deleted key still appears like a deletion except, when you explicitly list or retrieve deleted keys. Most operations on a key in the deleted state will fail except for listing a deleted key, recovering it or purging it
'
az keyvault key list-deleted --vault-name ContosoVault

:'
# Transition state
When you delete a key in a key vault with soft-delete enabled, it may take a few seconds for the transition to complete. During this transition, it may appear that the key is not in the active state or the deleted state.

Just like key vaults, a deleted key, secret, or certificate, remains in deleted state for up to 90 days, unless you recover it or purge it.
'
az keyvault key recover --name ContosoFirstKey --vault-name ContosoVault

# To permanently delete (also known as purging) a soft-deleted key, which will not be recoverable
az keyvault key purge --name ContosoFirstKey --vault-name ContosoVault
az keyvault purge --name ContosoVault --location westus 

# Purge protection
az keyvault create --name ContosoVault --resource-group ContosoRG --location westus --enable-soft-delete true --enable-purge-protection true
az keyvault update --name ContosoVault --resource-group ContosoRG --enable-purge-protection true

# Key access policy
az keyvault set-policy --name ContosoVault --key-permissions get create delete list update import backup restore recover purge

az keyvault secret delete --vault-name ContosoVault -name SQLPassword
az keyvault secret list-deleted --vault-name ContosoVault
az keyvault secret recover --name SQLPassword --vault-name ContosoVault
az keyvault secret purge --name SQLPAssword --vault-name ContosoVault



