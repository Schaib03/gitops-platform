variable "cluster_name" {
  description = "Name of the kind cluster."
  type        = string
  default     = "platform"
}

variable "node_image" {
  description = "kindest/node image. Empty uses the default of the installed kind version."
  type        = string
  default     = ""
}

variable "worker_nodes" {
  description = "Number of worker nodes next to the control plane."
  type        = number
  default     = 1

  validation {
    condition     = var.worker_nodes >= 0 && var.worker_nodes <= 3
    error_message = "Use between 0 and 3 workers on a laptop."
  }
}

variable "argocd_chart_version" {
  description = "Version of the argo-cd Helm chart."
  type        = string
  default     = "10.18.2"
}

variable "argocd_apps_chart_version" {
  description = "Version of the argocd-apps Helm chart used to create the root application."
  type        = string
  default     = "2.0.8"
}

variable "repo_url" {
  description = "Git repository Argo CD syncs from."
  type        = string
  default     = "https://github.com/Schaib03/gitops-platform.git"
}

variable "target_revision" {
  description = "Branch, tag or commit Argo CD follows."
  type        = string
  default     = "main"
}
