
#------------------
# AZURE PSREMOTING
#------------------
# https://techcommunity.microsoft.com/t5/itops-talk-blog/powershell-basics-connecting-to-vms-with-azure-psremoting/ba-p/428403

# Windows VM
Enable-AzVMPSRemoting -Name 'vm-win-01' -ResourceGroupName 'azure-cloudshell-demo' -Protocol https -OsType Windows
<#
The enabling command performs the following:
• Based on the Operating System, it ensures WinRM (Windows) or SSH (Linux) is setup.
• It ensures Network Security Group rules are in place to allow communication to the target, again based on communications type.
• For Linux VMs, it installs PowerShell core on the target system.
#>

# OPTION 1
$script = 'get-service win*'

Invoke-AzVMCommand -Name $rgName -ResourceGroupName $rgName `
  -Credential (get-credential) `
  -ScriptBlock { $script } 

# For Linux VM
$keyPath = '/home/michael/.ssh/id_rsa'
$script = 'uname -a'

Invoke-AzVMCommand -Name $vmName -ResourceGroupName $rgName `
  -UserName $userName -KeyFilePath $keyPath `
  -ScriptBlock { $script }


# OPTION 2 INTERACTIVELY
Enter-AzVM -name $vmName -ResourceGroupName $rgName -Credential (get-credential)
<#
PS C:\Users\demo-admin\Documents> $hostname
PS C:\Users\demo-admin\Documents> get-service Win*
exit
#>

<#
One important note is that this method relies on your VMs having Public IP addresses and ports open to your VMs; it does not work for private IPs. This means SSH and WinRM are open ports. To resolve that, simply close them down when you when done with Disable-AzVMPSRemoting.
#>

Disable-AzVMPSRemoting -Name vm-win-02 -ResourceGroupName azure-cloudshell-demo
<#
When executed, the cmdlet will
• Remove the ports from the Network Security Group
• For Windows VMs, Remove PowerShell Remoting from Windows VMs and reset UAC
• For Linux VMS, Restore to original SSH Daemon Config & restart sshd service to pick the config
#>

# Linux VM
Enable-AzVMPSRemoting -Name 'vm-lin-01' -ResourceGroupName 'azure-cloudshell-demo' -Protocol ssh -OsType Linux



#---------------------
# DISK INITIALIZATION
#---------------------
# https://devblogs.microsoft.com/scripting/use-powershell-to-initialize-raw-disks-and-to-partition-and-format-volumes/

$diskLabel = 'abcde'

Get-Disk | Where partitionstyle -eq ‘raw’ |
Initialize-Disk -PartitionStyle MBR -PassThru |
New-Partition -AssignDriveLetter -UseMaximumSize |
Format-Volume -FileSystem NTFS -NewFileSystemLabel $diskLabel -Confirm:$false  

