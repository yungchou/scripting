# https://www.altaro.com/hyper-v/vm-memory-pressure-powershell/

$Computer = $env:COMPUTERNAME

$VMName = "WIN10"
[regex]$rx = "(?<=\\\\).*(?=\\)"

$c = get-counter -listset 'Hyper-V Dynamic Memory VM' -ComputerName $computer | 
Select -expand PathsWithInstances | where { $_ -match $VMName }

Get-Counter -counter $c -SampleInterval 2 -MaxSamples 10

Get-Counter -Counter $c | 
Select-object -expandproperty Countersamples |
Sort-object -property InstanceName | 
Select-object -property InstanceName, 
@{Name = "Counter"; Expression = { Split-path $_.path -Leaf } },
Cookedvalue, timestamp,
@{Name = "VMHost"; Expression = { $rx.Match((Split-Path $_.path)).value.ToUpper() } } |
Format-Table

Get-Counter -Counter $c | 
Select-object -expandproperty Countersamples |
Sort-object -property InstanceName | 
Select-object -property InstanceName, 
@{Name = "Counter"; Expression = { Split-path $_.path -Leaf } },
Cookedvalue, timestamp,
@{Name = "VMHost"; Expression = { $rx.Match((Split-Path $_.path)).value.ToUpper() } } |
Out-GridView -Title "Dynamic Memory Counters"

1..10 | foreach {
  $data = Get-Counter -Counter $c | Select-object -expandproperty Countersamples |
  Sort-object -property InstanceName
  clear-Host
  $data | Select-object -property InstanceName, 
  @{Name = "Counter"; Expression = { Split-path $_.path -Leaf } },
  Cookedvalue, timestamp,
  @{Name = "VMHost"; Expression = { $rx.Match((Split-Path $_.path)).value.ToUpper() } } |
  Format-Table
  Start-sleep -Seconds 2
}

$computer = $env:COMPUTERNAME
[regex]$rx = "(?<=\\\\).*(?=\\)"

$VMName = "SRV2"
#get the available counters
$c = get-counter -listset 'Hyper-V Dynamic Memory VM' -ComputerName $computer | 
Select -expand PathsWithInstances | where { $_ -match $VMName } 

1..5 | foreach {
  Get-Counter -Counter $c | Select-object -expandproperty Countersamples |
  Sort-object -property InstanceName | 
  Select-object -property InstanceName, 
  @{Name = "Counter"; Expression = { Split-path $_.path -Leaf } },
  Cookedvalue, TimeStamp,
  @{Name = "VMHost"; Expression = { $rx.Match((Split-Path $_.path)).value.ToUpper() } } |
  ConvertTo-WPFGrid -Title "Dynamic Memory Counters" -Timeout 10 -Height 300 -Width 600 -CenterScreen
}

$computer = $env:COMPUTERNAME
$VMName = "SRV2"
[regex]$rx = "(?<=\\\\).*\($VMName\)\\.*Pressure"

#get the available counters
get-counter -listset 'Hyper-V Dynamic Memory VM' -ComputerName $computer | 
Select -expand PathsWithInstances | where { $_ -match $rx }

$computer = $env:COMPUTERNAME
$VMName = "SRV2"
[regex]$rx = "(?<=\\\\).*\($VMName\)\\.*Pressure"
[regex]$rxCounter = "(?<=\\\\).*(?=\\)"

#get the available counters
$c = get-counter -listset 'Hyper-V Dynamic Memory VM' -ComputerName $computer | 
Select -expand PathsWithInstances | where { $_ -match $rx } 

for ($i = 0; $i -lt 12; $i++) {
  Get-Counter -Counter $c | Select-object -expandproperty Countersamples |
  Sort-Object -property Path |  
  Select-Object -property @{Name = "VMHost"; Expression = { $rxCounter.Match((Split-Path $_.path)).value.ToUpper() } },
  @{Name = "VMName"; Expression = { $_.InstanceName.toUpper() } }, 
  @{Name = "Counter"; Expression = { Split-Path $_.path -Leaf } },
  Cookedvalue, TimeStamp  |
  ConvertTo-WPFGrid -Title "Memory Pressure for $VMName" -Timeout 5 -Height 180 -Width 530 -CenterScreen
}


