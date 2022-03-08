resource "azurerm_network_interface" "server" {
  count = length(local.domain.servers)

  name                = "${var.prefix}-srv-${count.index}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "static"
    subnet_id                     = azurerm_subnet.servers.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.servers_subnet_cidr, 100 + count.index)
    public_ip_address_id          = azurerm_public_ip.server[count.index].id
  }
}

resource "azurerm_network_interface_security_group_association" "server" {
  count = length(local.domain.servers)

  network_interface_id      = azurerm_network_interface.server[count.index].id
  network_security_group_id = azurerm_network_security_group.windows.id
}

resource "azurerm_virtual_machine" "server" {
  count = length(local.domain.servers)

  name                  = local.domain.servers[count.index].name
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.server[count.index].id]
  vm_size               = var.server_vm_size

  # Delete OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Delete data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    #id = data.azurerm_image.server.id

    # az vm image list --offer WindowsServer --all --output table
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.server_image_version.sku
    version   = var.server_image_version.version
  }
  storage_os_disk {
    name              = "srv-${count.index}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = local.domain.servers[count.index].name
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
    kind = "server"
  }
}

resource "null_resource" "provision_server_once_dc_has_been_created" {
  provisioner "local-exec" {
    working_dir = "${path.root}/../ansible"
    command     = "/bin/bash -c 'source venv/bin/activate && ansible-playbook servers.yml -v'"
  }

  # Note: the dependance on 'azurerm_virtual_machine.server' applies to *all* resources created from this block
  # The provisioner will only be run once all workstations have been created (not once per workstation)
  # c.f. https://github.com/hashicorp/terraform/issues/15285
  depends_on = [
    azurerm_virtual_machine.dc,
    azurerm_virtual_machine.server
  ]
}
