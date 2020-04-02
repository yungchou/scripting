

$vmConfig = `

"        New-AzureVMConfig                   "+'`'+"`n" + 
"            -ImageName    $VMImageName      "+'`'+"`n" +
"            -InstanceSize $VMSize           "+'`'+"`n" +
"            -Name         $VMname           "+'`'+"`n" +
"            -availabilitysetname $AvailabilitySet "+'`'+"`n" +
"            -DiskLabel    $VMImageName      "+'|'+"`n" +
"        Add-AzureProvisioningConfig         "+'`'+"`n" +
"            -Windows                        "+'`'+"`n" +
"            -DisableAutomaticUpdates        "+'`'+"`n" +
"            -AdminUserName $VMAdminUserName "+'`'+"`n" +
"            -Password      $VMAdminPassword "

$vmDisks += 

if ($VMConfigSet.DataDisks.Length -gt 0) {
 
    foreach ($disk in $VMConfigSet.DataDisks) { 
    
        $vmConfig += '|'+"`n" +

"        Add-AzureDataDisk        "+'`'+"`n" +
"            -CreateNew             "+'`'+"`n" +
"            -DiskLabel    $disk[0] "+'`'+"`n" +
"            -DiskSizeInGB $disk[1] "+'`'+"`n" +
"            -LUN 0 "

    }
}

if ($VMConfigSet.Endpoints.Length -gt 0) {
 
    foreach ($endpoint in $VMConfigSet.Endpoints) { 

        $vmConfig += '|'+"`n" +

"        Add-AzureEndpoint            "+'`'+"`n" +
"           -Name          $endpoint[0] "+'`'+"`n" +
"           -Protocol      $endpoint[1] "+'`'+"`n" +
"           -PublicPort    $endpoint[2] "+'`'+"`n" +
"           -LocalPort     $endpoint[3] "+'`'+"`n"

        if ( ($VMConfigSet.Endpoints.Length -eq 8) {

"           -LBSetName              $endpoint[4] "+'`'+"`n" +
"           -ProbePort              $endpoint[5] "+'`'+"`n" +
"           -ProbeProtocol          $endpoint[6] "+'`'+"`n" +
"           -ProbeIntervalInSeconds $endpoint[7] "+'`'+"`n"

        }

    }

}