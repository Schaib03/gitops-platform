# Secrets are generated here and written straight into the cluster, so they never
# appear in Git. They do end up in the Terraform state, which is local and ignored.
# A shared environment would use External Secrets Operator or Sealed Secrets instead.

locals {
  namespaces = toset(["data", "payflow", "corebank", "monitoring"])
}

resource "kubernetes_namespace_v1" "this" {
  for_each = local.namespaces

  metadata {
    name = each.key
  }

  depends_on = [kind_cluster.this]
}

resource "random_password" "postgres" {
  for_each = toset(["admin", "payflow", "corebank"])

  length  = 24
  special = false
}

resource "random_password" "payflow_secret_key" {
  length = 50
}

resource "random_password" "corebank_jwt" {
  length  = 48
  special = false
}

resource "random_password" "corebank_admin" {
  length  = 16
  special = false
}

resource "random_password" "grafana_admin" {
  length  = 16
  special = false
}

resource "kubernetes_secret_v1" "postgres" {
  metadata {
    name      = "postgres-credentials"
    namespace = kubernetes_namespace_v1.this["data"].metadata[0].name
  }

  data = {
    POSTGRES_PASSWORD = random_password.postgres["admin"].result
    PAYFLOW_PASSWORD  = random_password.postgres["payflow"].result
    COREBANK_PASSWORD = random_password.postgres["corebank"].result
  }
}

resource "kubernetes_secret_v1" "payflow" {
  metadata {
    name      = "payflow-secrets"
    namespace = kubernetes_namespace_v1.this["payflow"].metadata[0].name
  }

  data = {
    DATABASE_URL      = "postgres://payflow:${random_password.postgres["payflow"].result}@postgres.data.svc.cluster.local:5432/payflow"
    DJANGO_SECRET_KEY = random_password.payflow_secret_key.result
  }
}

resource "kubernetes_secret_v1" "corebank" {
  metadata {
    name      = "corebank-secrets"
    namespace = kubernetes_namespace_v1.this["corebank"].metadata[0].name
  }

  data = {
    DATABASE_PASSWORD = random_password.postgres["corebank"].result
    JWT_SECRET        = random_password.corebank_jwt.result
    ADMIN_PASSWORD    = random_password.corebank_admin.result
  }
}

resource "kubernetes_secret_v1" "grafana" {
  metadata {
    name      = "grafana-admin"
    namespace = kubernetes_namespace_v1.this["monitoring"].metadata[0].name
  }

  data = {
    admin-user     = "admin"
    admin-password = random_password.grafana_admin.result
  }
}
