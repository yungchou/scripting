## Sample PowerShell script that displays information about the Azure VM

# list of subscriptions
$subs = @("0260ee5f-3381-4817-84a6-e032ecade07a", "e4d29948-2aef-4b0b-85c2-aa7ab15085b4")

#$VMlist = @()

### Need to initialize initial Array object with fake data to establish
### the number of Data disk columns that will be captured in final output

$VMlist = @(New-Object -TypeName PSObject)
$VMlist | Add-Member -Type NoteProperty -Name Subscription       -Value "---"
$VMlist | Add-Member -Type NoteProperty -Name Name               -Value "---"
$VMlist | Add-Member -Type NoteProperty -Name CPU_Cores          -Value 0
$VMlist | Add-Member -Type NoteProperty -Name RAM_GB             -Value 0
$VMlist | Add-Member -Type NoteProperty -Name OSType             -Value "---"
$VMlist | Add-Member -Type NoteProperty -Name PowerState         -Value "---"
#$VMlist | Add-Member -Type NoteProperty -Name ProvisioningState  -Value "---"
$VMlist | Add-Member -Type NoteProperty -Name OSDiskSize         -Value 0
$VMlist | Add-Member -Type NoteProperty -Name OSDiskType         -Value "---"
$VMlist | Add-Member -Type NoteProperty -Name DataDiskSize1      -Value 0
$VMlist | Add-Member -Type NoteProperty -Name DataDiskType1      -Value "---"
$VMlist | Add-Member -Type NoteProperty -Name DataDiskSize2      -Value 0
$VMlist | Add-Member -Type NoteProperty -Name DataDiskType2      -Value "---"
$VMlist | Add-Member -Type NoteProperty -Name DataDiskSize3      -Value 0
$VMlist | Add-Member -Type NoteProperty -Name DataDiskType3      -Value "---"

ForEach ($sub in $subs) {
  (Get-date).tostring() + " - Switching to Subscription $sub"
  $AzureContext = Set-AzContext -SubscriptionId $sub
  $VMs = Get-AzVM -status

  If ($AzureContext.Subscription.Id -eq $sub) { ## If the subscription does not match then Set-AzContext failed to switch to the desired subscription.
    (Get-date).tostring() + " - Switched  to Subscription $sub" + " / " + $AzureContext.Subscription.Name
    ForEach ($VM in $VMs) {
      (Get-date).tostring() + " -   Looking up information for VM " + $VM.Name
      $VMObj = New-Object -TypeName PSObject

      # line below creates dynamic variables on the fly 
      # such as $SizeEastUs, $SizeCanada, ... to hold 
      # all of the East US VM sizes

      if (!(Test-Path variable:global:$("size"+$VM.Location))) { New-Variable -Name ("size" + $VM.Location) -Value (Get-AzVMSize -location ($VM.Location)) }

      $VMProperties = (Get-Variable -Name ("size" + $VM.Location)).value | Where-Object { $_.name -eq $vm.HardwareProfile.VmSize }  

      $VMObj | Add-Member -Type NoteProperty -Name Subscription       -Value $AzureContext.Subscription.Id
      $VMObj | Add-Member -Type NoteProperty -Name Name               -Value $VM.Name
      $VMObj | Add-Member -Type NoteProperty -Name CPU_Cores          -Value $VMProperties.NumberOfCores
      $VMObj | Add-Member -Type NoteProperty -Name RAM_GB             -Value ($VMProperties.MemoryInMB / 1024)
      $VMObj | Add-Member -Type NoteProperty -Name OSType             -Value $VM.StorageProfile.OsDisk.OsType.toString()
      $VMObj | Add-Member -Type NoteProperty -Name PowerState         -Value $VM.PowerState
      #$VMObj | Add-Member -Type NoteProperty -Name ProvisioningState  -Value $VM.ProvisioningState
      $VMObj | Add-Member -Type NoteProperty -Name OSDiskSize         -Value $VM.StorageProfile.OSDisk.DiskSizeGB
      $VMObj | Add-Member -Type NoteProperty -Name OSDiskType         -Value $VM.StorageProfile.OSDisk.ManagedDisk.StorageAccountType  ##  VM must be running for this to return a valid value

      if (($vm.StorageProfile.DataDisks.Count) -gt 0) {
        $xx = 0
        ForEach ($DataDisk in $vm.StorageProfile.DataDisks) {
          $xx++
          $VMObj | Add-Member -Type NoteProperty -Name ("DataDiskSize" + $xx)    -Value $DataDisk.DiskSizeGB
          $VMObj | Add-Member -Type NoteProperty -Name ("DataDiskType" + $xx)    -Value $DataDisk.ManagedDisk.StorageAccountType  ## provide VM is running
        }
      }

      $VMlist += $VMObj; # $VMObj | FT
    }

  }
  Else {
    (Get-date).tostring() + " - ERROR: Skipping Subscription $sub"
  }
}

$VMlist | FT *
$json = $VMlist[1..($VMlist.Count)] | ConvertTo-Json
$csv = $VMlist[1..($VMlist.Count)] | ConvertTo-Csv


