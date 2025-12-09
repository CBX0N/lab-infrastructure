resource "helm_release" "flux" {
  depends_on       = [talos_cluster_kubeconfig.this]
  name             = "flux"
  namespace        = "flux-system"
  repository       = "https://fluxcd-community.github.io/helm-charts"
  chart            = "flux2"
  create_namespace = true
  cleanup_on_fail  = true
}

resource "helm_release" "flux_sync" {
  depends_on       = [helm_release.flux]
  name             = "flux-sync"
  namespace        = helm_release.flux.namespace
  repository       = "https://fluxcd-community.github.io/helm-charts"
  chart            = "flux2-sync"
  create_namespace = true
  cleanup_on_fail  = true
  values = [
    yamlencode({
      gitRepository = {
        spec = {
          url = var.flux.git_repository
          secretRef = {
            name = "flux-system"
          }
          interval = "1m0s"
          ref = {
            branch = var.flux.repo_tag
          }
        }
      }
      kustomization = {
        spec = {
          interval = "30s"
          path     = var.flux.path
          prune    = true
        }
      }
    })
  ]
}

resource "kubernetes_secret" "flux_ssh_key" {
  metadata {
    name      = "flux-system"
    namespace = helm_release.flux.namespace
  }
  data = {
    "identity"     = base64decode(var.flux.private_key)
    "identity.pub" = base64decode(var.flux.public_key)
    "known_hosts"  = var.flux.known_hosts
  }
}