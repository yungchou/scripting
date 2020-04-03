#region [RTM]

function pick-one-item {

  param (
    [array  ]$thisList = @('East Asia','South Central US', 'West Europe', 'UAE North', 'South Afraica North'), 
    [string ]$itemDescription ='Azure Region', 
    [boolean]$gui = $false
    )

  if ($gui) {

    $thisOne = $thisList | Out-GridView -Title "$itemDescription List" -PassThru
  
  } else {
  
    if ($thisList.count -eq 1) { $thisOne = $thisList[0] 
    } else {
      
      $i=1; $tempList = @()

      foreach ( $item in $thisList )  {
          $tempList+="`n$i.`t$item" 
          $i++
      }

      do {
          write-host "`nHere's the $itemDescription list `n$tempList"
          $thePick = Read-Host "`nWhich $itemDEscription"
      } while(1..$tempList.length -notcontains $thePick)

      $thisOne = $thisList[($thePick-1)]
    }
  }

  write-host "$(get-date -f T) - Selecting '$thisOne' from the $itemDescription list " -f green -b black

  return $thisOne
  
}

function azure-vm-image-sku {

  param (

    [boolean]$gui = $false, 
    
    [string]$region = (pick-one-item `
      -thisList (Get-AzLocation).DisplayName `
      -itemDescription "Azure region" `
      -gui $gui ),

    [string]$publisher = (pick-one-item `
      -thisList (Get-AzVMImagePublisher -Location $region).PublisherName `
      -itemDescription "Azure $region publisher" `
      -gui $gui ),

    [string]$offer = (pick-one-item `
      -thisList (Get-AzVMImageOffer -Location $region -PublisherName $publisher).offer `
      -itemDescription "Azure $region $publisher's Offer" `
      -gui $gui ),  

    [string]$itemDescription = "Azure $region $publisher $offer Sku"

    )

  return $sku = (pick-one-item `
    -thisList (Get-AzVMImageSku -Location $region -PublisherName $publisher -Offer $offer).skus `
    -itemDescription $itemDescription `
    -gui $gui )

}

#region [RTM]

function pick-azure-gallery-template-id {

$thisPublisherPattern = 'microsoft' ; $thisTemplateIDPattern = 'sql' 

write-host "`nDefault string pattern for querying 'Publisher': '$thisPublisherPattern'" -f Yellow -b black
write-host "Default string pattern for querying 'Azure gallery template ID': '$thisTemplateIDPattern'"  -f Yellow -b black

$argGTobj = Get-AzureResourceGroupGalleryTemplate 

$action = '?'
while ($action.ToLower() -notin ('1','2','3','4')) {
$action = read-host "Change the above values? (1-No, 2-Both, 3-Publlisher, 4-Template ID)"
}

if ($action -in ('2','3')) {

$thisPublisherPattern = ''  

while (!$thisPublisherPattern) {
$thisPublisherPattern = read-host "`nEnter the name or a string pattern for querying publisher name"
}

}

$publisher = pick-one-from `
                 -thisList ($argGTobj | select publisher -Unique `
                                      | where publisher -like "*$thisPublisherPattern*").publisher `
                 -BasedOn 'Azure gallery template publisher'

if ($action -in ('2','4')) {

$thisTemplateIDPattern = ''

while (!$thisTemplateIDPattern) {
$thisTemplateIDPattern = read-host "`nEnter the ID or a string pattern for querying Azure gallery template ID "
}

}

if ($id=( ($argGTobj | where publisher -eq $publisher).Identity -like "*$thisTemplateIDPattern*" ) ) {

 return (pick-one-from -thisList $id -BasedOn 'Azure gallery template') 

}
else {return ''}

}

function set-up-folder {

    param ([string]$here)

    if (!(Test-Path $here)) { New-Item $here -type directory | out-null 
         write-host "`nCreated the folder, $here" -f yellow 
   }

    return $here

}

function create-session {

    param ( [boolean]$prefix = $false, [boolean]$seed=$false, [boolean]$desktopFolder = $false )
    
    $thisSession = @{}

    if ($prefix) {
    do {$initials = (read-host 'Enter 3 chars (initials) as a prefix for the deployment').ToLower()}
    until ( 
        ($initials.length -eq 3) -and
        ($initials[0] -in [char]'a'..[char]'z') -and 
        ($initials[1] -in [char]'a'..[char]'z') -and 
        ($initials[2] -in [char]'a'..[char]'z') 
    )
    $thisSession.prefix = $initials
    }

    if ($seed) { $thisSession.seed = get-date -format 'mmss' }

    if ($desktopFolder) {
    $thisSession.desktopFolder = setup-folder -here "$home\Desktop\ITCamp\$($thisSession.prefix)" }

    Write-Verbose "`n$thisSession"

    return $thisSession

}

function Set-TimeZone {
<#
  credit to Ben Baird
  ref: https://gallery.technet.microsoft.com/scriptcenter/Set-TimeZone-function-b5ed93b5
  run tzutil /l to find the timezone id
#>
	param(
		[parameter(Mandatory=$true)]
		[string]$TimeZone
	)
	
	$osVersion = (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").GetValue("CurrentVersion")
	$proc = New-Object System.Diagnostics.Process
	$proc.StartInfo.WindowStyle = "Hidden"

	if ($osVersion -ge 6.0)
	{
		# OS is newer than XP
		$proc.StartInfo.FileName = "tzutil.exe"
		$proc.StartInfo.Arguments = "/s `"$TimeZone`""
	}
	else
	{
		# XP or earlier
		$proc.StartInfo.FileName = $env:comspec
		$proc.StartInfo.Arguments = "/c start /min control.exe TIMEDATE.CPL,,/z $TimeZone"
	}

	$proc.Start() | Out-Null

}

function Get-MyVariable
{ #ref: http://powershell.com/cs/blogs/tips/archive/2013/02/20/finding-built-in-variables.aspx
    $builtin = [psobject].Assembly.GetType('System.Management.Automation.SpecialVariables').GetFields('NonPublic,Static') | 
      Where-Object FieldType -eq ([string]) | 
      ForEach-Object GetValue $null

    $builtin += 'MaximumAliasCount','MaximumDriveCount','MaximumErrorCount', 'MaximumFunctionCount', 'MaximumFormatCount', 'MaximumVariableCount', 'FormatEnumerationLimit', 'PSSessionOption', 'psUnsupportedConsoleApplications'

    Get-Variable |
      Where-Object { $builtin -NotContains $_.Name } |
      Select-Object -Property Name, Value, Description
}

#endregion

#endregion
