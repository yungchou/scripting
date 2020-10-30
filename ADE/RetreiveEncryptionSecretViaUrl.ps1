# RUN THIS SCRIPT IN A RESCUE VM ATTACHED WITH A TO-BE-DECRYPTED DISK
# https://gist.github.com/vermashi/7f3544a911cf0ed75d6b32b562b77237

<# AS NEEDED INSTALL AZURE RM
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name AzureRM -AllowClobber
Import-Module -Name AzureRM
#>

Param(
  [Parameter(Mandatory = $true,
    HelpMessage = "URL to the secret stored in the keyvault")]
  [ValidateNotNullOrEmpty()]
  [string]$secretUrl,

  [Parameter(Mandatory = $false,
    HelpMessage = "URL to the KEK")]
  [ValidateNotNullOrEmpty()]
  [string]$kekUrl,

  [Parameter(Mandatory = $true,
    HelpMessage = "Location where the retrieved secret should be written to")]
  [ValidateNotNullOrEmpty()]
  [string]$secretFilePath
)

#Login-AzureRmAccount;

#Install Active directory module
Install-Module -Name MSOnline;

#Get current logged in user and active directory tenant details
$ctx = Get-AzureRmContext;
$adTenant = $ctx.Tenant.Id;
$currentUser = $ctx.Account.Id

#Parse the secret URL
$secretUri = [System.Uri] $secretUrl;

#Retrieve keyvault name, secret name and secret version from secret URL
$keyVaultName = $secretUri.Host.Split('.')[0];
$secretName = $secretUri.Segments[2].TrimEnd('/');
$secretVersion = $secretUri.Segments[3].TrimEnd('/');

#Set permissions for the current user to unwrap keys and retrieve secrets from KeyVault
Set-AzureRmKeyVaultAccessPolicy `
  -VaultName $keyVaultName `
  -PermissionsToKeys unwrapKey `
  -PermissionsToSecrets get `
  -UserPrincipalName $currentUser;

#Retrieve secret from KeyVault secretUrl
$keyVaultSecret = Get-AzureKeyVaultSecret `
  -VaultName $keyVaultName `
  -Name $secretName `
  -Version $secretVersion;

$secretBase64 = $keyVaultSecret.SecretValueText;

#Unwrap secret if the secret is wrapped with KEK
if ($kekUrl) {

  ###############################################################
  # Initialize ADAL libraries and get authentication context 
  # required to make REST API called against KeyVault REST APIs. 
  ###############################################################

  # Set well-known client ID for AzurePowerShell
  $clientId = "1950a258-227b-4e31-a9cf-717495945fc2" 
  # Set redirect URI for Azure PowerShell
  $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
  # Set Resource URI to Azure Service Management API
  $resourceAppIdURI = "https://vault.azure.net"
  # Set Authority to Azure AD Tenant
  $authority = "https://login.windows.net/$adTenant"
  # Create Authentication Context tied to Azure AD Tenant
  $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
  # Acquire token
  $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "Auto")
  # Generate auth header 
  $authHeader = $authResult.CreateAuthorizationHeader()
  # Set HTTP request headers to include Authorization header
  $headers = @{'x-ms-version' = '2014-08-01'; "Authorization" = $authHeader }

  #####################################################################################
  # 1. Retrieve the secret from KeyVault
  # 2. If Kek is not NULL, unwrap the secret with Kek by making KeyVault REST API call
  # 3. Convert Base64 string to bytes and write to the BEK file
  #####################################################################################

  #Call KeyVault REST API to Unwrap 
  $jsonObject = @"
    {
      "alg": "RSA-OAEP",
      "value" : "$secretBase64"
    }
"@

  $unwrapKeyRequestUrl = $kekUrl + "/unwrapkey?api-version=2015-06-01";

  $result = Invoke-RestMethod `
    -Method POST `
    -Uri $unwrapKeyRequestUrl `
    -Headers $headers `
    -Body $jsonObject `
    -ContentType "application/json";

  #Convert Base64Url string returned by KeyVault unwrap to Base64 string
  $secretBase64 = $result.value;
}

$secretBase64 = $secretBase64.Replace('-', '+');
$secretBase64 = $secretBase64.Replace('_', '/');

if ($secretBase64.Length % 4 -eq 2) {
  $secretBase64 += '==';
}
elseif ($secretBase64.Length % 4 -eq 3) {
  $secretBase64 += '=';
}

if ($secretFilePath) {
  $bekFileBytes = [System.Convert]::FromBase64String($secretBase64);
  [System.IO.File]::WriteAllBytes($secretFilePath, $bekFileBytes);
}
