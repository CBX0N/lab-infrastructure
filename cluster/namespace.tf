resource "kubernetes_namespace" "metallb_system" {
  depends_on = [ talos_cluster_kubeconfig.this ]
  metadata {
    name = "metallb-system"
    labels = {
        "pod-security.kubernetes.io/enforce" = "privileged"
        "pod-security.kubernetes.io/enforce-version" = "latest"
    }
  }
}