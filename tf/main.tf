resource "proxmox_virtual_environment_download_file" "debian_12" {
  content_type          = "iso"
  datastore_id          = "local"
  file_name             = "debian-12-generic-amd64.img"
  node_name             = var.pve_node
  url                   = var.debian_image_url
  checksum              = var.debian_image_checksum
  checksum_algorithm    = var.debian_image_checksum_algorithm
  overwrite             = true
  overwrite_unmanaged   = true
}

resource "proxmox_virtual_environment_file" "user_config" {
  content_type  = "snippets"
  datastore_id  = "local"
  node_name     = var.pve_node

  source_raw {
    data        = file("cloudinit/user-config.yaml")
    file_name   = "user-config.yaml"
  }
}

resource "proxmox_virtual_environment_file" "vendor_config" {
  content_type  = "snippets"
  datastore_id  = "local"
  node_name     = var.pve_node

  source_raw {
    data        = file("cloudinit/vendor-config.yaml")
    file_name   = "vendor-config.yaml"
  }
}
resource "proxmox_virtual_environment_vm" "debian_12_test" {
    depends_on          = [ 
        proxmox_virtual_environment_file.user_config,
        proxmox_virtual_environment_file.vendor_config 
    ]
    name                = "debian-12"
    description         = "Debian 12 created with Terraform"
    tags                = ["terraform", "debian"]
    node_name           = var.pve_node

    cpu {
        cores   = 2
    }
    memory {
        dedicated = 2048
        floating  = 2048
    }

    disk {
        datastore_id    = "local-lvm"
        file_id         = proxmox_virtual_environment_download_file.debian_12.id
        interface       = "virtio0"
        iothread        = true
        discard         = "on"
        ssd             = true
    }
    network_device {
        bridge          = "vmbr0"
        model           = "virtio"
        mac_address     = "BC:24:11:44:BF:88"  # Adresse MAC fixe
    }
    operating_system {
        type            = "l26"
    }
    agent {
        enabled         = true
    }
    initialization {
        ip_config {
            ipv4 {
                address     = "dhcp"
            }
        }
        # Link cloud-init yaml files
        user_data_file_id   = proxmox_virtual_environment_file.user_config.id
        vendor_data_file_id = proxmox_virtual_environment_file.vendor_config.id
    }
}

output "debian_12_test_ip_address" {
    value = proxmox_virtual_environment_vm.debian_12_test.ipv4_addresses
}

