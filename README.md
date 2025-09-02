# Figment DevOps Lab

A production-shaped demo that deploys a tiny FastAPI service to Kubernetes with Helm, manages infra and releases with Terraform, publishes images to GHCR, and uses a Makefile for one-touch workflows. The app exposes /healthz and Prometheus /metrics for basic observability.


## Features

- App: FastAPI with /healthz and /metrics
- Images: Built by GitHub Actions → GHCR (ghcr.io/oelnajmi/validator-sim:<commit-sha> + :dev) 
- Kubernetes: Helm chart with labels, liveness/readiness probes
- Infra as Code: Terraform for Helm release (local & cloud) and AWS EKS (cloud)
- Cost hygiene (cloud): 1× micro node, no NAT/ALB, access via kubectl port-forward
- Makefile: cluster-up, app-up, port-forward, demo-stop, deploy-sha, etc.
- Optional monitoring: Prometheus/Grafana (local dockerized), or kube-prometheus-stack in k3d


## Architecture

- Container image: ghcr.io/oelnajmi/validator-sim:<tag>
- Release control: Terraform pins image tags by commit SHA for deterministic rollouts/rollbacks
- Cloud path (default demo):
  - Terraform creates EKS (VPC with public subnets, 1× micro node)
  - Helm installs the app (Service = ClusterIP)
  - Access via kubectl port-forward (no public LB by default)
- Local path (optional):
  - k3d/k3s with Traefik ingress, optional kube-prometheus-stack for dashboards 


## Repo Layout

app/                   # FastAPI service
helm/charts/myapp/     # Helm chart (Deployment/Service/ServiceMonitor template)
terraform/             # Terraform controlling Helm release (image tag by SHA)
infra/eks/             # Terraform EKS module (VPC, cluster, node group)
.github/workflows/     # CI: build & push to GHCR
Makefile               # one-touch targets (cluster up/down, app up/down, promote SHA, etc.)


## Quickstart (Cloud / EKS — default demo)
- AWS CLI configured
- Terraform remote state (S3 + DynamoDB) already created 
- GHCR image exists (CI built at least once)

Spin up → deploy → check:
# From repo root
make cluster-up          # creates EKS, updates kubeconfig, scales CoreDNS to 1 on micro nodes
make app-up              # installs/updates Helm release via Terraform

# Tunnel the Service to localhost (change PORT if 8080 is busy)
make port-forward        # forwards myapp:80 -> localhost:8080

# New terminal: quick health & metrics
curl -s http://localhost:8080/healthz
curl -s http://localhost:8080/metrics | head

Promote a specific image (by commit SHA)
# Update running image to an exact commit and keep terraform plan clean
make deploy-sha SHA=<your_commit_sha>

Tear down (stop billing)
# Stop port-forward (Ctrl+C), then:
make demo-stop           # app-down + cluster-down


## Optional: Local (k3d) path
This replicates the app locally with Traefik ingress and (optionally) in-cluster Prometheus/Grafana.
# Create local cluster
k3d cluster create dev --agents 2

# Deploy via Helm
helm upgrade --install myapp helm/charts/myapp

# Access (Traefik):
curl -s http://myapp.localtest.me:8080/healthz
curl -s http://myapp.localtest.me:8080/metrics | head


## CI/CD

- GitHub Actions workflow builds and pushes images to GHCR  
- Helm chart updates use the Git SHA as the image tag  
- Kubernetes pulls and runs the updated image automatically  
- Terraform can be integrated into CD pipelines for full infrastructure automation  

## Observability 

- /healthz → liveness/readiness checks (Kubernetes probes)
- /metrics → Prometheus exposition (Python runtime + custom validator_requests_total{path=…})
- For cloud demos, metrics are available via port-forward; in-cluster Prometheus/Grafana is not installed by default to keep the footprint/cost minimal.


# Cost & Cleanup

- The EKS control plane bills hourly while the cluster exists.
- Keep the cluster up only during demos/practice:
- Bring up: make cluster-up && make app-up
- Demo: make port-forward
- Tear down: make demo-stop
- Terraform state backend (S3/DynamoDB) remains—pennies of storage, recommended to keep.


## Notes

- Public URL: not created by default. To expose publicly, add either a LoadBalancer Service (NLB) or an ALB Ingress via AWS Load Balancer Controller + ACM cert.
- CORS, auth, and WAF are out of scope here but straightforward extensions.
- This repo focuses on DevOps plumbing—immutable builds, declarative infra, controlled rollouts, and basic observability—ready to extend with more app endpoints or a frontend.
