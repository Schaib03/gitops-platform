# 1. A local Kubernetes cluster in Docker.
resource "kind_cluster" "this" {
  name           = var.cluster_name
  node_image     = var.node_image != "" ? var.node_image : null
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      # Traefik is scheduled here and binds the host ports below.
      labels = {
        "ingress-ready" = "true"
      }
      extra_port_mappings {
        container_port = 80
        host_port      = 80
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 443
      }
    }

    dynamic "node" {
      for_each = range(var.worker_nodes)
      content {
        role = "worker"
      }
    }
  }
}

provider "kubernetes" {
  host                   = kind_cluster.this.endpoint
  client_certificate     = kind_cluster.this.client_certificate
  client_key             = kind_cluster.this.client_key
  cluster_ca_certificate = kind_cluster.this.cluster_ca_certificate
}

provider "helm" {
  kubernetes = {
    host                   = kind_cluster.this.endpoint
    client_certificate     = kind_cluster.this.client_certificate
    client_key             = kind_cluster.this.client_key
    cluster_ca_certificate = kind_cluster.this.cluster_ca_certificate
  }
}

# 2. Argo CD itself. Everything after this point is managed by Argo CD from Git.
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = "argocd"
  create_namespace = true
  wait             = true
  timeout          = 600

  values = [file("${path.module}/values/argocd.yaml")]
}

# 3. The root application (app-of-apps). It points at apps/ in this repository, and
#    each file there is an Application for one component.
resource "helm_release" "root_app" {
  name       = "root-app"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = var.argocd_apps_chart_version
  namespace  = "argocd"

  values = [templatefile("${path.module}/values/root-app.yaml.tftpl", {
    repo_url        = var.repo_url
    target_revision = var.target_revision
  })]

  # Secrets first, so the apps can start as soon as Argo CD syncs them.
  depends_on = [
    helm_release.argocd,
    kubernetes_secret_v1.postgres,
    kubernetes_secret_v1.payflow,
    kubernetes_secret_v1.corebank,
    kubernetes_secret_v1.grafana,
  ]
}
