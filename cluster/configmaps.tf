resource "kubernetes_config_map" "control_plane_ips" {
  depends_on = [ talos_cluster_kubeconfig.this ]
  metadata {
    name = "metallb-vip-range"
  }
  data = {
    ip_range = "${local.control_plane_ips[0]}-${local.control_plane_ips[length(local.control_plane_ips) - 1]}"
  }
}