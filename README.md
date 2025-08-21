This project demonstrates deploying a containerized Python application to a local Kubernetes cluster with monitoring and observability features.  

## Features

- Python app with health and metrics endpoints
- Helm chart for deployment
- Prometheus for metrics collection
- Grafana for visualization
- CI/CD with GitHub Actions
- Images hosted on GitHub Container Registry (GHCR)

## Architecture

- GitHub Actions builds and pushes images to GitHub Container Registry (GHCR).  
- The application container image is stored at: `ghcr.io/oelnajmi/validator-sim:<tag>`.  
- Kubernetes (via Helm) deploys the application and references the GHCR image.  
- The application exposes two endpoints:
  - `/healthz` for health checks
  - `/metrics` for Prometheus metrics
- Prometheus discovers the application using the ServiceMonitor resource and scrapes metrics.  
- Grafana connects to Prometheus and visualizes those metrics in dashboards.  
- Traefik ingress routes external traffic to the application at `myapp.localtest.me:8080`.

## Monitoring

- Prometheus scrapes application metrics from `/metrics`
- ServiceMonitor ensures the app is registered for scraping
- Grafana dashboards visualize key metrics

## CI/CD

- GitHub Actions workflow builds and pushes images to GHCR
- Helm chart updates use the Git SHA as the image tag
- Kubernetes pulls and runs the updated image automatically

## Local Development

1. Start k3d cluster:  
   bash: k3d cluster create dev --agents 2
2. Deploy the app:
   bash: helm upgrade --install myapp helm/charts/myapp
3. Access the app at: http://myapp.localtest.me:8080


