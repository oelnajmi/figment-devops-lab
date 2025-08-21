# Figment DevOps Lab

This project demonstrates deploying a containerized Python application to a local Kubernetes cluster with monitoring and observability features.

## Features

- Python app with health and metrics endpoints  
- Helm chart for deployment  
- Prometheus for metrics collection  
- Grafana for visualization  
- CI/CD with GitHub Actions  
- Images hosted on GitHub Container Registry (GHCR)  
- Infrastructure as Code with Terraform  

## Architecture

- GitHub Actions builds and pushes images to GitHub Container Registry (GHCR).  
- The application container image is stored at: `ghcr.io/oelnajmi/validator-sim:<tag>`.  
- Terraform provisions Helm releases for both the application and observability stack (Prometheus + Grafana).  
- The application exposes two endpoints:  
  - `/healthz` for health checks  
  - `/metrics` for Prometheus metrics  
- Prometheus discovers the application via the ServiceMonitor resource created by Terraform and scrapes metrics.  
- Grafana connects to Prometheus and visualizes those metrics in dashboards.  
- Traefik ingress routes external traffic to the application at `myapp.localtest.me:8080`.  

## Monitoring

- Prometheus scrapes application metrics from `/metrics`  
- ServiceMonitor ensures the app is registered for scraping (managed by Terraform)  
- Grafana dashboards visualize key metrics  

## CI/CD

- GitHub Actions workflow builds and pushes images to GHCR  
- Helm chart updates use the Git SHA as the image tag  
- Kubernetes pulls and runs the updated image automatically  
- Terraform can be integrated into CD pipelines for full infrastructure automation  

## Local Development

### Using Helm directly (quick start)

1. Start k3d cluster:  
   ```bash
   k3d cluster create dev --agents 2
   ```
2. Deploy the app:  
   ```bash
   helm upgrade --install myapp helm/charts/myapp
   ```
3. Access the app at:  
   [http://myapp.localtest.me:8080](http://myapp.localtest.me:8080)  

### Using Terraform (full stack)

1. Start k3d cluster (if not already running):  
   ```bash
   k3d cluster create dev --agents 2
   ```
2. Initialize Terraform:  
   ```bash
   cd terraform
   terraform init
   ```
3. Apply Terraform configuration:  
   ```bash
   terraform apply
   ```
4. Access the app:  
   [http://myapp.localtest.me:8080](http://myapp.localtest.me:8080)  
5. Access Grafana dashboards:  
   [http://grafana.localtest.me:8080](http://grafana.localtest.me:8080)  

