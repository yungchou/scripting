
# Script1

# Setup Log File

$LogFile = 'C:\\Temp\\Post-Install-Script.log'

# Setup Additional Disk On VM

Add-Content -Value 'Setting up drives ' -Path $LogFile
try {
  $NewDisk = @(Get-Disk | Sort-Object Number | Where-Object partitionstyle -eq 'raw')
  $DiskLetter = @('E')
  $DiskLabel = @('DATA')

  for ($i = 0; $i -lt $NewDisk.Count ; $i++) {
    $DiskNum = $NewDisk[$i].Number
    Get-Disk $DiskNum | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -DriveLetter $DiskLetter[$i] -UseMaximumSize
    Format-Volume -DriveLetter $DiskLetter[$i] -FileSystem NTFS -NewFileSystemLabel $DiskLabel[$i] -Confirm:$false
    Add-Content -Value 'Format Drive $DiskNum - $($DiskLetter[$i]) - $($DiskLabel[$i])' -Path $LogFile
  }
}
catch {
  Add-Content -Value 'Drive Setup Failed' -Path $LogFile
  Add-Content -Value $Error[0] -Path $LogFile
  Exit
}

# Setup Additional Local Administrator Access

$DomainGroup = 'machineDomainGroupName'
$LocalGroup = 'Administrators'
$Computer = $env:computername
$Domain = $env:userdomain
[bool] $groupExists = $false;

$group = [ADSI]'WinNT://$Computer/$LocalGroup'
$members = @($group.Invoke('Members'))

foreach ($member in $members) {
  try {
    $memberName = $member.GetType().Invokemember('Name', 'GetProperty', $null, $member, $null)
    if ($memberName -eq $DomainGroup) {
      Add-Content -Value '$DomainGroup already exists under Administrators' -Path $LogFile
      $groupExists = $true;
    }
  }
  catch {}
}

if ($groupExists -eq $false) {
  ([ADSI]'WinNT://$Computer/$LocalGroup,group').psbase.Invoke('Add', ([ADSI]'WinNT://$Domain/$DomainGroup').path)
}

