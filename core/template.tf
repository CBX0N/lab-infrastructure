resource "proxmox_storage_iso" "ubuntu_cloudimg" {
  storage  = "local"
  url      = var.ubuntu_template.image
  pve_node = "pve"
  filename = "noble-server-cloudimg-amd64.img"
}

resource "null_resource" "ubuntu_template" {
  connection {
    host = var.proxmox.host
    user = var.proxmox.user
    private_key = base64decode(var.proxmox.private_key)
  }
  provisioner "remote-exec" {
    when = create
    inline = [
      "qm destroy 9000",
      "qm create 9000 --name ubuntu-template --memory 2048 --net0 virtio,bridge=vmbr0 --scsihw virtio-scsi-pci",
      "qm set 9000 --scsi0 local-lvm:0,import-from=/var/lib/vz/template/iso/${proxmox_storage_iso.ubuntu_cloudimg.filename}",
      "qm set 9000 --ide2 local-lvm:cloudinit",
      "qm set 9000 --boot order=scsi0",
    "qm template 9000"]
  }
}