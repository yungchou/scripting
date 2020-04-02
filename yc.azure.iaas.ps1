
#region [INCLUDING FILES]
$include="https://dnddaig.blob.core.windows.net/aaa/yc.azure.iaas.v2.0.ps1"
try   { iex ($content=(New-Object Net.WebClient).DownloadString($include)) }
catch { write-host "Error while loading `n$include" -b black -f red; throw 'ERROR!'  }
Write-Host "Included the file, `n$include" -b black -f green
#endregion

$prefix='yc'
$QSKfolder = 'c:\_azure.iaas'  # User-defined

#region [required validation]

Connect-AzAccount

$azSubName = pick-one-item `
  -thisList (get-AzSubscription).Name `
  -itemDescription 'Subscription' `
  -gridView $true

$tag = "$prefix$(get-date -format 'HHmmss')"
write-host "`nSession ID = $tag" -b black -f green

#endregion

#region [optional customization]

[int]$totalVMs = 2       # User-specified

# Notice that the script acquires an image name based on the specified vm label which may be changed 
# in Windows Azure. In such case the query will not return a VM image and later when executing 
# New-AzureVMConfig, it will result in an error since not able to validate ImageName.
# If so, run the following query against a string pattern, here "windows server 2012"
#
# get-azurevmimage | Select-Object -Property label | where {$_.label -like "windows server 2012*"} | Out-GridView
#
# and validate the image label in hte next statement.

$vmSku = azure-vm-image-sku `
  -region 'southcentralus' `
  -publisher 'microsoftWindowsServer' `
  -offer 'windows-server-2012-vhd-server-prod-stage' `
  -gridView $true

$myImage = Get-AzVMImage `
           | where {$_.Label -like '*Windows*'} 

$AzureVMImageName = $myImage.ImageName

# As of Oct, 2013 
# ExtraSmall, Small, Medium, Large, ExtraLarge, A6, A7
$AzureVMSize           = 'Small'     # User-specified
$myDataDiskSize        = 20  #GB     # User-specified
 
$VMNamePrefix          = $tag
$myVMAdminUserName     = 'qsk'       # User-defined
$myVMAdminPassword     = 'Passw0rd1' # User-defined

write-host ('VM admin credentials: user name = '+$myVMAdminUserName+' , pwd = '+$myVMAdminPassword) -b black -f r

$myAvailabilitySetName = $tag+'-as'  # User-defined
$myEndpointName        = $tag+'-ep'  # User-deinfed
$myLoadBalancerName    = $tag+'-lb'  # User-defined

# East US, West US, East Asia, Southeast Asia, North Europe, West Europe
$AzureRegion = 'East US' # User-specified

$myServiceName         = $tag
$myStorageAccountName  = $tag

#endregion

# As of Aug, 2014, Azure module is located at
# 'C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Azure.psd1'
Import-Module Azure

Set-AzureSubscription    $myAzureSubscription
Select-AzureSubscription $myAzureSubscription

"----------------------------------------------------------"
"Windows Azure QSK deployment starts at "+($when=Get-Date)
"----------------------------------------------------------"

New-AzureStorageAccount -StorageAccountName    $myStorageAccountName `
                        -Location              $AzureRegion 

Set-AzureStorageAccount -StorageAccountName    $myStorageAccountName `
                        -GeoReplicationEnabled $false

New-AzureService        -ServiceName           $myServiceName `
                        -Location              $AzureRegion

Set-AzureSubscription   -SubscriptionName      $myAzureSubscription  `
                        -CurrentStorageAccount $myStorageAccountName

for ($i=0; $i -lt $totalVMs; $i++) {

$myVMname = "$VMNamePrefix-$i"

# For demonstration, this set of VM configurations attaches one data disk 
# to each VM, and also puts all the VMs into a load-balancer on port 80. 
# To add additional data disks, simply replicate the Add-AzureDataDisk 
# statement and validate the label and the LUN number. And if a 
# load-balancer is not needed, simply take out the Add-AzureEndpoint
# statement.
 
New-AzureVMConfig -ImageName    $AzureVMImageName `
                  -InstanceSize $AzureVMSize `
                  -Name         $myVMname `
                  -availabilitysetname $myAvailabilitySetName `
                  -DiskLabel "OS" `
| Add-AzureProvisioningConfig -Windows `
                              -DisableAutomaticUpdates `
                              -AdminUserName $myVMAdminUserName `
                              -Password      $myVMAdminPassword `
| Add-AzureDataDisk -CreateNew -DiskSizeInGB $myDataDiskSize `
                    -DiskLabel 'QSK-DataDisk0' `
                    -LUN 0 `
| Add-AzureEndpoint -Name          $myEndpointName `
                    -Protocol      tcp `
                    -LocalPort     80 `
                    -PublicPort    80 `
                    -LBSetName     $myLoadBalancerName `
                    -ProbePort     8080 `
                    -ProbeProtocol tcp `
                    -ProbeIntervalInSeconds 15 `
| New-AzureVM -ServiceName $myServiceName

# Step 6
Get-AzureRemoteDesktopFile -ServiceName $myServiceName `
                           -Name        $myVMname `
                           -LocalPath   "$QSKfolder\$myVMname.rdp"

}

"`n--------------------------------------------------------"
"Windows Azure QSK deployment ends at "+($when=Get-Date)
"--------------------------------------------------------"

#------------------
# clean Up routine
#------------------
function clean_up_the_deployment_of {

    param ( [string]$thisSession )

if (!$thisSession) { return "Empty session." } 

$error.clear()

$ticking = New-Object system.Diagnostics.Stopwatch  
write-host `n'At '(get-date)', ticking started for cleaning up ' `
        $thisSession`n -b black -f Yellow
$ticking.Start()

    get-azureservice `
    | where {$_.label -like ($thisSession+'*')} `
    | remove-azureservice -force -deleteall

    do {
        start-sleep -s 20
        try{
        get-azurestorageaccount `
        | where {$_.label -like ($thisSession+'*')} `
        | remove-azurestorageaccount -ErrorAction SilentlyContinue
        }
        catch { 'Somethign went very wrong, if we are here.' } 
       }
    until ($?)

    get-azureAffinityGroup  `
    | where {$_.label -like ($thisSession+'*')} `
    | remove-azureAffinityGroup

$ticking.Stop();  
write-host `n"At "(get-date)', ticking stopped for '$thisSession `
    -b black -f Yellow

$ticks = $ticking.elapsed 
$elapsedTime = [system.String]::Format("{0:00}:{1:00}:{2:00}.{3:00}", 
    $ticks.Hours, $ticks.Minutes, $ticks.Seconds, $ticks.Milliseconds / 10)

write-host `n"Cleanup Time = $elapsedTime"`n `
    -b black -f Yellow

}

# Wait for a confirmation before deletion

do    { $now = read-host "`nDelete the VMs and deployed resoruces? y/n" }
until ( $now -eq 'y' -or $now -eq 'Y' )

#delete downloaded rdp files
"$QSKfolder\$tag"+'*.rdp' | del

clean_up_the_deployment_of $tag

