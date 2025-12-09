locals {
  control_plane_ips = [
    for vm in proxmox_vm_qemu.talos-control-plane : vm.default_ipv4_address
  ]

  talos_config = [
    yamlencode({
      machine = {
        network = {
          nameservers = [
            "${var.dns.ns1}",
          ]
        }
        install = {
          image = "${var.talos_control_plane.image}"
        }
      }
    })
  ]
}

resource "proxmox_storage_iso" "talos_linux" {
  storage  = "local"
  url      = var.talos_control_plane.boot_image
  pve_node = "pve"
  filename = "nocloud-amd64.iso"
}

resource "proxmox_vm_qemu" "talos-control-plane" {
  name      = "tal-cp-0${count.index + 1}"
  agent     = 1
  bios      = "ovmf"
  machine   = "q35"
  skip_ipv6 = true

  balloon = 0
  memory  = 4096
  cpu {
    cores   = 2
    sockets = 1
    type    = "host"
  }

  boot   = "order=scsi1;scsi0"
  scsihw = "virtio-scsi-pci"
  disks {
    scsi {
      scsi0 {
        cdrom {
          iso = "local:iso/${proxmox_storage_iso.talos_linux.filename}"
        }
      }
      scsi1 {
        disk {
          cache      = "none"
          discard    = true
          emulatessd = true
          format     = "raw"
          size       = "20G"
          storage    = "local-lvm"
        }
      }
    }
  }

  efidisk {
    efitype = "4m"
    storage = "local-lvm"
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
  tags        = "iac"
  count       = var.talos_control_plane.count
  target_node = "pve"
}

resource "proxmox_vm_qemu" "talos-worker" {
  name      = "tal-wk-0${count.index + 1}"
  agent     = 1
  bios      = "ovmf"
  machine   = "q35"
  skip_ipv6 = true

  balloon = 0
  memory  = 8192
  cpu {
    cores   = 4
    sockets = 1
    type    = "host"
  }

  boot   = "order=scsi1;scsi0"
  scsihw = "virtio-scsi-pci"
  disks {
    scsi {
      scsi0 {
        cdrom {
          iso = "local:iso/${proxmox_storage_iso.talos_linux.filename}"
        }
      }
      scsi1 {
        disk {
          cache      = "none"
          discard    = true
          emulatessd = true
          format     = "raw"
          size       = "20G"
          storage    = "local-lvm"
        }
      }
    }
  }

  efidisk {
    efitype = "4m"
    storage = "local-lvm"
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
  tags        = "iac"
  count       = 5
  target_node = "pve"
}

resource "dns_a_record_set" "cluster_control_plane" {
  count      = var.talos_control_plane.count
  addresses  = local.control_plane_ips
  name       = "cluster"
  zone       = var.dns.zone
}

resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "control_plane" {
  cluster_name       = "talos-Cluster"
  cluster_endpoint   = var.talos_control_plane.cluster_endpoint
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_control_plane.talos_version
  kubernetes_version = var.talos_control_plane.kubernetes_version
}

resource "talos_machine_configuration_apply" "control_plane" {
  count                       = var.talos_control_plane.count
  depends_on                  = [proxmox_vm_qemu.talos-control-plane]
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.control_plane.machine_configuration
  node                        = proxmox_vm_qemu.talos-control-plane["${count.index}"].default_ipv4_address
  config_patches              = local.talos_config
}

data "talos_machine_configuration" "worker" {
  cluster_name       = "talos-Cluster"
  cluster_endpoint   = var.talos_control_plane.cluster_endpoint
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_control_plane.talos_version
  kubernetes_version = var.talos_control_plane.kubernetes_version
}

resource "talos_machine_configuration_apply" "worker" {
  count                       = 5
  depends_on                  = [proxmox_vm_qemu.talos-worker]
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = proxmox_vm_qemu.talos-worker["${count.index}"].default_ipv4_address
  config_patches              = local.talos_config
}

resource "talos_machine_bootstrap" "control_plane" {
  depends_on = [
    talos_machine_configuration_apply.control_plane
  ]
  node                 = proxmox_vm_qemu.talos-control-plane[0].default_ipv4_address
  client_configuration = talos_machine_secrets.this.client_configuration
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    talos_machine_bootstrap.control_plane
  ]
  node                 = proxmox_vm_qemu.talos-control-plane[0].default_ipv4_address
  client_configuration = talos_machine_secrets.this.client_configuration
}

resource "local_file" "kubeconfig" {
  content  = talos_cluster_kubeconfig.this.kubeconfig_raw
  filename = "${path.module}/kubeconfig"
}