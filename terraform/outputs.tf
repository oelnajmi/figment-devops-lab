output "grafana_ingress_host" {
  value       = "grafana.localtest.me:8080"
  description = "Grafana URL via Traefik ingress"
}

output "app_ingress_host" {
  value       = "myapp.localtest.me:8080"
  description = "App URL via Traefik ingress"
}
