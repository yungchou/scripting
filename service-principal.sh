# https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest

az ad sp list \
  --all \
  --show-mine \
  --query "[].{appDisplayName:appDisplayName, appId:appId, accountEnabled:accountEnabled}" \
  -o table

# CREATE SERVICE PRINCIPAL

# 1. Password-based authentication

# Without any authentication parameters, password-based authentication 
# is used with a random password created for you.
# The output for a service principal with password authentication includes 
# the password key. Make sure you copy this value - it can't be retrieved. 
# If you forget the password, reset the service principal credentials.

# 2. Certificate-based authentication

# This argument requires that you hold an existing certificate. 
# Certificates should be in an ASCII format such as PEM, CER, or DER. 
# Pass the certificate as a string, or use the @path format to load 
# the certificate from a file.

# Create a self-signed cert
az ad sp create-for-rbac \
  --name ServicePrincipalName \
  --create-cert \
  -o table

# Create a self-signed cert stored in the keyvault
az ad sp create-for-rbac \
  --name ServicePrincipalName \
  --create-cert \
  --cert CertName \
  --keyvault VaultName \
  -o table

# Use a specifiied cert
az ad sp create-for-rbac \
  --name ServicePrincipalName \
  --cert \
  "-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----"

# additional options
#  --cert @/path/to/cert.pem
#  --cert CertName --keyvault VaultName

# ASSIGN ROLES
# When restricting a service principal's permissions, the Contributor role should be removed.
az role assignment create --assignee APP_ID --role Reader -o table 
az role assignment delete --assignee APP_ID --role Contributor -o table
az role assignment list --assignee APP_ID -o table

# RESET CREDENTIALS
az ad sp credential reset --name APP_ID
