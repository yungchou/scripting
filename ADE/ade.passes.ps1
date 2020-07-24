

# A. Stop the VM
          
$vmName = 'VMName'
$rg = 'Resource group name'
$vm3 = get-azureRMvm -VMName $vmName -ResourceGroupName $rg
stop-azureRMvm -ResourceGroupName $vm3.ResourceGroupName -Name $vm3.Name

     
# B. Set encryption setting to null from VM model and start the VM

$vm3 = get-azureRMvm -VMName $vmName -ResourceGroupName $rg
$vm3.StorageProfile.OsDisk.EncryptionSettings = $null
#Null means the VM has never been encrypted before. 
Update-AzureRMVM -ResourceGroupName $vm3.ResourceGroupName -VM $vm3
Start-AzureRMVM -name $vmname -ResourceGroupName $rg -Verbose

# Add disk
resource "azurerm_managed_disk" "external_1" {
  name                 = "${var.web_server_name}-disk-02"
  location             = var.web_server_location
  resource_group_name  = azurerm_resource_group.web_server_rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "10"
}

resource "azurerm_virtual_machine_data_disk_attachment" "external_1" {
  managed_disk_id    = azurerm_managed_disk.external_1.id
  virtual_machine_id = azurerm_virtual_machine.web_server.id
  lun                = "2"
  caching            = "ReadWrite"
}

# From Step 1 to 8 is to provision a KEY Vault and create a client secret

1.Create an Application Registration in AAD. 
 
resource "azurerm_azuread_application" "diskencryptionapp" {
  name = "diskencryptionapp"
}

2. Create a SPN

resource "azurerm_azuread_service_principal" "diskencryptionapp" {
  application_id = azurerm_azuread_application.diskencryptionapp.application_id
}


3. Create a random password for Application registration Client Secret
resource "random_string" "password" {
  length  = 32
  special = false
}

4.Create a client secret
resource "azuread_application_password" "azureadspnpassword" {
  application_id = azurerm_azuread_application.diskencryptionapp.id
  value          = random_string.password.result
  end_date       = "2022-01-01T01:00:00Z"
}

5. Generate the output of client secret
output "client_secret" {
  description = "Client Secret"
  value       = random_string.password.result
}


6. Create a key vault and provide proper access policy.
resource "azurerm_key_vault" "mykeyvault" {
  name                            = var.keyvaultname
  location                        = var.web_server_location
  resource_group_name             = azurerm_resource_group.web_server_rg.name
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  tenant_id                       = var.tenant_id
  sku {
    name = "standard"
  }
  access_policy {
    tenant_id = var.tenant_id
    object_id = data.azurerm_azuread_service_principal.diskencryptionapp.object_id
    secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge",
    ]
    key_permissions = [
    "Get",
    "List",
    "Update",
    "Create",
    "Import",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "WrapKey",
    "UnwrapKey",
    ]
    certificate_permissions = [
    "Get",
    "List",
    "Update",
    "Create",
    "Import",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "ManageContacts",
    "ManageIssuers",
    "GetIssuers",
    "ListIssuers",
    "SetIssuers",
    "DeleteIssuers",
    ]
  }
  access_policy {
    tenant_id = var.tenant_id
    object_id = var.personalobjectid
    secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Restore",
    "Purge",
    ]
    key_permissions = [
    "Get",
    "List",
    "Update",
    "Create",
    "Import",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "WrapKey",
    "UnwrapKey",
    ]
  }

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
  tags = {
    environment = "Production"
  }
}

7.Create a Secret in the key vault 
resource "azurerm_key_vault_secret" "secret-sauce" {
  name         = var.secretname
  value        = "password@123"
  key_vault_id = azurerm_key_vault.hpvault01.id
  tags = {
    environment = "Production"
  }
}

8. Create a key in the key vault

resource "azurerm_key_vault_key" "diskencryptionkey" {
  name         = "diskencryptionkey"
  key_vault_id = azurerm_key_vault.hpvault01.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
  "decrypt",
  "encrypt",
  "sign",
  "unwrapKey",
  "verify",
  "wrapKey",
  ]
}

Step 9 to 16 for creating windows VM

9. Create a Resource Group
resource "azurerm_resource_group" "web_server_rg" {
  name     = var.web_server_rg
  location = var.web_server_location
}



10. Create a VNET
resource "azurerm_virtual_network" "web_server_vnet" {
  name                = "${var.resource_prefix}-vnet"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
  address_space       = [var.web_server_address_space]
}


11. Create a Subnet

resource "azurerm_subnet" "web_server_subnet" {
  name                 = "${var.resource_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.web_server_rg.name
  virtual_network_name = azurerm_virtual_network.web_server_vnet.name
  address_prefix       = var.web_server_address_prefix[0]
}


12. Create a Network interface card
resource "azurerm_network_interface" "web_server_nic" {
  name                      = "${var.web_server_name}-nic"
  location                  = var.web_server_location
  resource_group_name       = azurerm_resource_group.web_server_rg.name
  network_security_group_id = azurerm_network_security_group.web_server_nsg.id

  ip_configuration {
    name                          = "${var.web_server_name}-ip"
    subnet_id                     = azurerm_subnet.web_server_subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.web_server_public_ip.id
  }
}


13. Create a Public IP

resource "azurerm_public_ip" "web_server_public_ip" {
  name                = "${var.web_server_name}-public-ip"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
  allocation_method   = var.environment == "production" ? "Static" : "Dynamic"
}


14.Create a NSG
resource "azurerm_network_security_group" "web_server_nsg" {
  name                = "${var.web_server_name}-nsg"
  location            = var.web_server_location
  resource_group_name = azurerm_resource_group.web_server_rg.name
}


15. Create NSG rule for RDP to the VM

resource "azurerm_network_security_rule" "web_server_nsg_rule_rdp" {
  name                        = "RDP Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.web_server_rg.name
  network_security_group_name = azurerm_network_security_group.web_server_nsg.name
}


16. Create a Windows VM

resource "azurerm_virtual_machine" "web_server" {
  name                             = var.web_server_name
  location                         = var.web_server_location
  resource_group_name              = azurerm_resource_group.web_server_rg.name
  network_interface_ids            = [azurerm_network_interface.web_server_nic.id]
  vm_size                          = "Standard_D4s_v3"
  availability_set_id              = azurerm_availability_set.avset.id
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "sql2019-ws2019"
    sku       = "sqldev"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.web_server_name}-os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    os_type           = "Windows"
    disk_size_gb      = 127
  }

  os_profile {
    computer_name  = var.web_server_name
    admin_username = "admina"
    admin_password = data.azurerm_key_vault_secret.secret-sauce.value
  }

  os_profile_windows_config {
    enable_automatic_upgrades = true
    provision_vm_agent        = true
  }
}


