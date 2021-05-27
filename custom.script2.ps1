###########
# Script 2:

# Dynamic Variables

$AdminADGroup_PRD = 'prdAdmin'
$AdminADGroup_NPD = 'nonPrdAdmin'

# Dynamic Variables

$ResourceGroup = Invoke-RestMethod -Headers @{'Metadata' = 'true' } -URI 'http://123.123.123.123/metadata/instance/compute/resourceGroupName?api-version=2019-08-15&format=text' -Method get

if ($ResourceGroup -like 'prdStringPattern') {
  $AdminADGroup = $AdminADGroup_PRD
} 
elseif ($ResourceGroup -like 'nonPrdStringPattern') {
  $AdminADGroup = $AdminADGroup_PRD
}
else {
  $AdminADGroup = $AdminADGroup_NPD
}

# Setup Log File

$LogFile = 'C:\\Temp\\Post-Install-Script.log'

# Create C:\\Temp directory

New-Item -ItemType Directory -Path 'C:\\Temp' -Force

# Change System Locale & Language

Set-WinSystemLocale en-US
Set-WinHomeLocation -GeoId 12
Set-Culture en-AU
& $env:SystemRoot\\System32\\control.exe 'intl.cpl,,/f:`'.\\usRegion.xml`''

# Set Timezone to Brisbane

# Get-TimeZone
# Get-TimeZone -ListAvailable
# Get-TimeZone -Name "us*"
Set-TimeZone -Name "Pacific Standard Time" -PassThru

# Move CDROM to Z:\\

(Get-WmiObject Win32_cdromdrive).drive | ForEach-Object {$a = mountvol $_ /l;mountvol $_ /d;$a = $a.Trim();mountvol z: $a}

# Setup Local Administrator Access

$DomainGroup = $AdminADGroup
$LocalGroup  = 'Administrators'
$Computer    = $env:computername
$Domain      = $env:userdomain
[bool] $groupExists = $false;

$group = [ADSI]'WinNT://$Computer/$LocalGroup'
$members = @($group.Invoke('Members'))

foreach($member in $members) {
try {
$memberName = $member.GetType().Invokemember('Name','GetProperty',$null,$member,$null)
if ($memberName -eq $DomainGroup)
{
Add-Content -Value '$DomainGroup already exists under Administrators' -Path $LogFile
$groupExists = $true;
}
}
catch {}
}

if ($groupExists -eq $false)
{
([ADSI]'WinNT://$Computer/$LocalGroup, group').psbase.Invoke('Add',([ADSI]'WinNT://$Domain/$DomainGroup').path)
}

# Install SSCM Agent

$SCCMSiteServer = 'abcde'

# Check SCCM client is already installed
if (Test-Path -PathType Leaf '$env:windir\\CCM\\CcmExec.exe') 
{
Write-Output 'SCCM Agent is already installed on VM'
} else 
{
Write-Output 'Install SCCM Agent on the machine'
$Url = 'http://$SCCMSiteServer/CCM_client/ccmsetup.exe'
$CCMSetupFile = '$env:windir\\temp\\ccmsetup.exe'
(New-Object System.Net.WebClient).DownloadFile($Url, $CCMSetupFile)
Start-Process $CCMSetupFile
Add-Content -Value 'SCCM Client File has been copied to local directory' -Path $LogFile

Add-Content -Value 'Starting DISM Cleanup'
Start-Process dism.exe -ArgumentList '/online /cleanup-Image /StartComponentCleanup' 

}
