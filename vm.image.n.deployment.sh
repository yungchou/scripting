:'
How to create a managed image of a virtual machine or VHD
https://docs.microsoft.com/en-us/azure/virtual-machines/linux/capture-image

To create a managed image, one needs to remove personal account information. 

One managed image supports up to 20 simultaneous deployments. Attempting to create more than 20 VMs concurrently, from the same managed image, may result in provisioning timeouts due to the storage performance limitations of a single VHD. To create more than 20 VMs concurrently, use a Shared Image Galleries image configured with 1 replica for every 20 concurrent VM deployments.

------

You can use the Azure VM Image Builder (Public Preview) service to build your custom image, no need to learn any tools, or setup build pipelines, simply providing an image configuration, and the Image Builder will create the Image. 

Azure Image Builder overview
https://docs.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-overview

'

# Step 1: Deprovision the VM
# SSH into the vm, then run
sudo waagent -deprovision+user
:' 
Only run this command on a VM that you will capture as an image. 
This command does not guarantee that the image is cleared of all 
sensitive information or is suitable for redistribution. 
The +user parameter also removes the last provisioned user account. 
To keep user account credentials in the VM, use only -deprovision.
'
# Step 2: Create VM image
az vm deallocate -g $rgName -n $vmName -o table
az vm generalize -g $rgName -n $vmName -o table

vmImgName=$vmName'-img'
az image create  -g $rgName -n $vmImgName --source $vmName -o table

# Step 3: Create a VM from the captured image
az image list -o table

#---> CONTINUE WIHT _rtm.vm.snippet.sh

# Step 4: Verify the deployment
az vm show -g theRgName -n theVmName -d -o table


