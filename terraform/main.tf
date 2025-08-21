#############################
# Monitoring stack (Prom+Grafana)
#############################
resource "helm_release" "kube_prom_stack" {
  name             = "kube-prom-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  version          = var.kube_prom_chart_version

  # Use your existing values file for Grafana ingress + admin password etc.
  values = [file("${path.module}/../helm/values-monitoring.yaml")]
}

#############################
# App (local Helm chart)
#############################
resource "helm_release" "myapp" {
  name       = "myapp"
  chart      = "../helm/charts/myapp"
  namespace  = "default"

  # Override image repo/tag via Terraform variables (v3 syntax)
  set = [
    {
      name  = "image.repository"
      value = var.image_repo
    },
    {
      name  = "image.tag"
      value = var.image_tag
    }
  ]
}

#############################
# ServiceMonitor for app (Prometheus scraping)
#############################
resource "kubernetes_manifest" "myapp_servicemonitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "myapp"
      namespace = "monitoring"
      labels = {
        release = "kube-prom-stack"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "myapp"
        }
      }
      namespaceSelector = {
        matchNames = ["default"]
      }
      endpoints = [{
        port     = "http"
        path     = "/metrics"
        interval = "15s"
      }]
    }
  }

  depends_on = [helm_release.kube_prom_stack, helm_release.myapp]
}

#############################
# Example alert rule (Pod restarts)
#############################
resource "kubernetes_manifest" "myapp_prometheusrule" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "myapp-rules"
      namespace = "monitoring"
      labels = {
        release = "kube-prom-stack"
      }
    }
    spec = {
      groups = [{
        name  = "myapp.rules"
        rules = [{
          alert = "PodRestartsHigh"
          expr  = "increase(kube_pod_container_status_restarts_total{namespace=\"default\"}[5m]) > 0"
          for   = "2m"
          labels = { severity = "warning" }
          annotations = {
            summary     = "Pod restarts detected in default namespace"
            description = "One or more pods restarted within the last 5 minutes."
          }
        }]
      }]
    }
  }

  depends_on = [helm_release.kube_prom_stack]
}
