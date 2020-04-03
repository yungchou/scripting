
<#

The function, azure-vm-image-sku, returns the sku of a user-selected 
Azure VM image interactively. It calls the function, pick-one-item, 
which accepts an item-list and returns a selected item interactively. 

Usage:

# Get a sku in the default text mode
azure-vm-image-sku 

# Get a sku with GUI
azure-vm-image-sku -gui $true

# Get a sku with optional switches
azure-vm-image-sku `
  -region 'targetAzureRegion' `
  -publisher 'targetPublisherName' `
  -offer 'targetOffer' `
  -gui $true

Examples: 

azure-vm-image-sku -region 'south central us' -gui $true

azure-vm-image-sku `
  -region 'south central us' `
  -publisher 'microsoftwindowsserver'

azure-vm-image-sku `
  -region 'south central us' `
  -publisher 'microsoftwindowsserver' `
  -offer 'windowsserver' 

© 2020 Yung Chou. All Rights Reserved.

#>

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

azure-vm-image-sku `
    -publisher 'microsoftwindowsserver' `
    -offer 'windowsserver' `
    -region 'south central us' `
    -gui $true

azure-vm-image-sku -gui $true 