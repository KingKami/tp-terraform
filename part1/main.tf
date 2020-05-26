provider "azurerm" {
    version = "~>2.0"
    subscription_id = var.subscription_id
    tenant_id = var.tenant_id
    features {}
}

resource "azurerm_resource_group" "RGMonoVM" {
    name = var.ressource_group_name
    location = var.location
}

resource "azurerm_virtual_network" "network" {
    name = var.virtual_network_name
    address_space = [var.virtual_network_address_space]
    location = azurerm_resource_group.RGMonoVM.location
    resource_group_name = azurerm_resource_group.RGMonoVM.name
}

resource "azurerm_subnet" "subnet" {
    name = var.subnet_name
    address_prefixes = [var.subnet_address_space]
    virtual_network_name = azurerm_virtual_network.network.name
    resource_group_name = azurerm_resource_group.RGMonoVM.name
}

resource "azurerm_public_ip" "IP_public" {
    name = var.public_ip_name
    location = var.location
    resource_group_name = azurerm_resource_group.RGMonoVM.name
    allocation_method = var.allocation_method
}

resource "azurerm_network_interface" "NIC" {
    name = var.network_interface_name
    location = var.location
    resource_group_name = azurerm_resource_group.RGMonoVM.name

    ip_configuration {
        name = var.ip_configuration_name
        subnet_id = azurerm_subnet.subnet.id
        private_ip_address_allocation = var.allocation_method
        public_ip_address_id = azurerm_public_ip.IP_public.id
    }
}

resource "azurerm_managed_disk" "manage-disk" {
    name = var.managed_disk_name
    location = var.location
    resource_group_name = azurerm_resource_group.RGMonoVM.name
    storage_account_type = var.disk_type
    create_option = var.disk_option
    disk_size_gb = var.managed_disk_sizeGB
}

resource "azurerm_virtual_machine" "VM" {
    name = var.vm_name
    location = var.location
    resource_group_name = azurerm_resource_group.RGMonoVM.name
    network_interface_ids = [azurerm_network_interface.NIC.id]
    vm_size = var.vm_size

    storage_os_disk {
        name = var.os_disk_name
        caching = var.disk_caching
        create_option = var.os_option
        managed_disk_type = var.disk_type
    }

    storage_data_disk {
        name = var.storage_disk_name
        managed_disk_type = var.disk_type
        create_option = var.disk_option
        disk_size_gb = var.storage_disk_sizeGB
        lun = var.storage_disk_lun
        caching = var.disk_caching
    }

    storage_image_reference {
        publisher = var.publisher
        offer = var.offer
        sku = var.sku
        version = var.os_version
    }

    os_profile {
        computer_name  = var.vm_name
        admin_username = var.login
        admin_password = var.password
    }

    os_profile_windows_config{}
}

resource "azurerm_virtual_machine_data_disk_attachment" "attachment" {
    managed_disk_id = azurerm_managed_disk.manage-disk.id
    virtual_machine_id = azurerm_virtual_machine.VM.id
    lun = var.managed_disk_lun
    caching = var.disk_caching
}