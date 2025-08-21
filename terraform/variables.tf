variable "image_repo" {
  description = "Container image repository"
  type        = string
  default     = "ghcr.io/oelnajmi/validator-sim"
}

variable "image_tag" {
  description = "Image tag (e.g., dev or a specific commit SHA)"
  type        = string
  default     = "dev"
}

variable "kube_prom_chart_version" {
  description = "kube-prometheus-stack chart version"
  type        = string
  # Pin a recent stable version; update if needed
  default     = "58.3.2"
}
