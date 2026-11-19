output "kubeconfig_context" {
  description = "kubectl context of the cluster."
  value       = "kind-${kind_cluster.this.name}"
}

output "urls" {
  description = "Services exposed through Traefik (*.localtest.me resolves to 127.0.0.1)."
  value = {
    argocd   = "http://argocd.localtest.me"
    grafana  = "http://grafana.localtest.me"
    payflow  = "http://payflow.localtest.me/docs"
    corebank = "http://corebank.localtest.me/swagger-ui.html"
  }
}

output "grafana_admin_password" {
  value     = random_password.grafana_admin.result
  sensitive = true
}

output "corebank_admin_password" {
  value     = random_password.corebank_admin.result
  sensitive = true
}
