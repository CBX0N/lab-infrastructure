locals {
  cloud_init = <<EOT
    #cloud-config
    package_reboot_if_required: true
    package_update: true
    package_upgrade: true
    packages:
      - bind9
      - bind9utils
      - bind9-doc
    users:
      - name: ${var.cloud_init.username}
        groups: sudo
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
        lock_passwd: false
        hashed_passwd: ${var.cloud_init.user_hashed_password}
    write_files:
      - path: /var/lib/bind/db.custom-zone
        content: |
          $TTL 86400
          @       IN      SOA     ns1.${var.dns.zone} admin.${var.dns.zone} (
                                  2025120901 ; Serial
                                  3600       ; Refresh
                                  1800       ; Retry
                                  604800     ; Expire
                                  300 )      ; Negative Cache TTL

                  IN      NS      ns1.${var.dns.zone}

          ; Required A records for the nameservers
          ns1     IN      A       ${var.dns.ns1}
          ns2     IN      A       192.168.0.206
      - path: /etc/bind/tsig.key
        content: |
          key "ddnskey" {
            algorithm hmac-sha256;
            secret "${var.dns.tsig_key}";
          };
      - path: /etc/bind/named.conf.options
        content: |
          options {
              directory "/var/cache/bind";
              forwarders {
                  1.1.1.1;
                  8.8.8.8;
              };
              
              allow-recursion { trusted; };
              allow-query { any; };
              allow-transfer { none; };
              dnssec-validation auto;
              listen-on { any; };
              listen-on-v6 { none; };
          };
      - path: /etc/bind/named.conf
        content: |
          include "/etc/bind/tsig.key";
          include "/etc/bind/named.conf.options";
          
          acl "trusted" {
              127.0.0.1;
              192.168.0.0/16;
          };

          zone "${var.dns.zone}" {
              type master;
              file "/var/lib/bind/db.custom-zone";
              allow-update { key ddnskey; };
          };
    runcmd:
      - sed -i 's|^OPTIONS=.*|OPTIONS="-u bind -4"|' /etc/default/named
      - systemctl restart bind9
  EOT
}

resource "local_file" "userdata_bind" {
  connection {
    host = var.proxmox.host
    user = var.proxmox.user
    private_key = base64decode(var.proxmox.private_key)
  }

  filename = "${path.module}/user_data_bind.yml"
  content  = local.cloud_init

  provisioner "remote-exec" {
    inline = ["rm /var/lib/vz/snippets/user_data_bind.yml"]
  }

  provisioner "file" {
    source      = local_file.userdata_bind.filename
    destination = "/var/lib/vz/snippets/user_data_bind.yml"
  }
}

resource "proxmox_vm_qemu" "bind_primary" {
  depends_on = [
    null_resource.ubuntu_template,
    local_file.userdata_bind
  ]
  name        = "bind-1"
  scsihw      = "virtio-scsi-pci"
  tags        = "iac"
  target_node = "pve"
  boot        = "order=scsi0"
  os_type     = "cloud-init"
  clone_id    = 9000
  full_clone  = true
  memory      = 4096
  cicustom    = "user=local:snippets/user_data_bind.yml"
  vm_state    = "started"
  ipconfig0   = "ip=${var.dns.ns1}/24,gw=192.168.0.1"

  lifecycle {
    replace_triggered_by = [local_file.userdata_bind]
    ignore_changes       = [ssh_host, ssh_port, default_ipv4_address]
  }

  cpu {
    cores = 2
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  serial {
    id   = 0
    type = "socket"
  }

  startup_shutdown {
    order            = -1
    shutdown_timeout = -1
    startup_delay    = -1
  }

  disks {
    scsi {
      scsi0 {
        disk {
          size    = "20G"
          storage = "local-lvm"
        }
      }
    }
    ide {
      ide1 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
  }
}

# resource "proxmox_vm_qemu" "bind_secondary" {
#   depends_on = [
#     null_resource.ubuntu_template,
#     local_file.userdata_bind,
#     proxmox_vm_qemu.bind_primary
#   ]
#   name        = "bind-2"
#   scsihw      = "virtio-scsi-pci"
#   tags        = "iac"
#   target_node = "pve"
#   boot        = "order=scsi0"
#   os_type     = "cloud-init"
#   clone_id    = 9000
#   full_clone  = true
#   memory      = 4096
#   cicustom    = "user=local:snippets/user_data_bind.yml"
#   vm_state    = "started"
#   ipconfig0   = "ip=192.168.0.206/24,gw=192.168.0.1"
#   cpu {
#     cores = 2
#   }
#   network {
#     id     = 0
#     model  = "virtio"
#     bridge = "vmbr0"
#   }
#   serial {
#     id   = 0
#     type = "socket"
#   }
#   disks {
#     scsi {
#       scsi0 {
#         disk {
#           size    = "20G"
#           storage = "local-lvm"
#         }
#       }
#     }
#     ide {
#       ide1 {
#         cloudinit {
#           storage = "local-lvm"
#         }
#       }
#     }
#   }
# }

