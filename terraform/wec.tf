resource "azurerm_network_interface" "wec" {
  name                = "${var.prefix}-wec-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "static"
    subnet_id                     = azurerm_subnet.servers.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.servers_subnet_cidr, 100)
    public_ip_address_id          = azurerm_public_ip.wec.id
  }
}

resource "azurerm_network_interface_security_group_association" "wec" {
  network_interface_id      = azurerm_network_interface.wec.id
  network_security_group_id = azurerm_network_security_group.windows.id
}


resource "azurerm_virtual_machine" "wec" {
  name                  = "windows-event-collector"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.wec.id]
  vm_size               = var.server_vm_size

  # Delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Delete data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    # az vm image list --offer WindowsServer --all --output table
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.server_image_version.sku
    version   = var.server_image_version.version
  }
  storage_os_disk {
    name              = "wec-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "WEC"
    admin_username = local.domain.default_local_admin.username
    admin_password = local.domain.default_local_admin.password
  }
  os_profile_windows_config {
    enable_automatic_upgrades = false
    timezone                  = "Central European Standard Time"
    winrm {
      protocol = "HTTP"
    }
  }

  tags = {
    kind = "windows-event-collector"
  }
}

resource "null_resource" "provision_wec_once_dc_has_been_created" {
  provisioner "local-exec" {
    working_dir = "${path.root}/../ansible"
    command     = "/bin/bash -c 'source venv/bin/activate && ansible-playbook windows-event-collector.yml -v'"
  }

  # Note: the dependance on 'azurerm_virtual_machine.workstation' applies to *all* resources created from this block
  # The provisioner will only be run once all workstations have been created (not once per workstation)
  # c.f. https://github.com/hashicorp/terraform/issues/15285
  depends_on = [
    azurerm_virtual_machine.dc,
    azurerm_virtual_machine.wec,
    azurerm_virtual_machine.es_kibana
  ]
}
