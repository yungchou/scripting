
az ad sp list \
  --all \
  --show-mine \
  -o table

# this does not work??
  --query "[*].[{DisplayName:DisplayName, AppId:AppId, AccountEnabled:AccountEnabled}]" \

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
az ad sp create-for-rbac --name ServicePrincipalName --create-cert -o table

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


spName='myServicePrincipalName'
az ad sp create-for-rbac --name $spName



