resource "kubernetes_config_map" "control_plane_ips" {
  metadata {
    name = "metallb-vip-range"
  }
  data = {
    ip-range = "${local.control_plane_ips[0]}-${local.control_plane_ips[length(local.control_plane_ips) - 1]}"
  }
}