SHELL := /bin/bash

# Current commit SHA
SHA := $(shell git rev-parse HEAD)

# Image tag to deploy; can be overridden: make deploy TAG=<sha>
TAG ?= $(SHA)

.PHONY: help deploy deploy-sha pin pin-sha plan apply show-image health prometheus grafana

help: ## Show available targets
	@awk -F':.*##' '/^[a-zA-Z0-9_-]+:.*##/ {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

deploy: ## Deploy image with TAG (default: current HEAD)
	cd terraform && terraform apply -var="image_tag=$(TAG)" -auto-approve

deploy-sha: ## Deploy the image matching current git commit
	cd terraform && terraform apply -var="image_tag=$(SHA)" -auto-approve

pin: ## Write demo.auto.tfvars.json with TAG (default: current HEAD) and show plan
	cd terraform && printf '{ "image_tag": "%s" }\n' "$(TAG)" > demo.auto.tfvars.json && terraform plan

pin-sha: ## Pin current git commit and show clean plan
	cd terraform && printf '{ "image_tag": "%s" }\n' "$(SHA)" > demo.auto.tfvars.json && terraform plan

plan: ## Terraform plan
	cd terraform && terraform plan

apply: ## Terraform apply using current defaults (variables.tf / *.auto.tfvars)
	cd terraform && terraform apply -auto-approve

show-image: ## Show running image in cluster
	kubectl -n default get deploy myapp -o=jsonpath='{.spec.template.spec.containers[0].image}'; echo

health: ## Check app health via Ingress
	curl -s http://myapp.localtest.me:8080/healthz

prometheus: ## Port-forward Prometheus (runs until Ctrl+C)
	kubectl -n monitoring port-forward svc/kube-prom-stack-kube-prome-prometheus 9090:9090

grafana: ## Print Grafana URL
	@echo "Open http://grafana.localtest.me:8080 (admin/admin unless changed)"

##### ───────────────────────────
##### EKS demo shortcuts
##### Prereqs: AWS creds configured; TF state bucket/table already exist.
##### ───────────────────────────

# Tunables (override with: make PORT=8081 …)
PORT       ?= 8080
NAMESPACE  ?= default

# Use Terraform's -chdir to avoid cd juggling
TF_EKS_DIR := infra/eks
TF_APP_DIR := terraform

.PHONY: cluster-up cluster-down kubeconfig cluster-status app-up app-down port-forward demo-start demo-stop

## Create/Update the EKS cluster (public subnets, 1× micro node)
cluster-up:
	terraform -chdir=$(TF_EKS_DIR) init
	terraform -chdir=$(TF_EKS_DIR) apply -auto-approve
	$(MAKE) kubeconfig
	# Scale CoreDNS to 1 on micro nodes to free a pod slot (safe for demos)
	kubectl -n kube-system scale deploy coredns --replicas=1 || true
	$(MAKE) cluster-status
	@echo "Tip: On t3.micro, scale CoreDNS to 1 so your app can schedule: \n  kubectl -n kube-system scale deploy coredns --replicas=1"

## Destroy the EKS cluster + VPC (stops control-plane billing)
cluster-down:
	# Optional: remove the app first to keep state tidy (ok to skip)
	- terraform -chdir=$(TF_APP_DIR) destroy -target=helm_release.myapp -auto-approve
	terraform -chdir=$(TF_EKS_DIR) destroy -auto-approve

## Update kubeconfig to point kubectl at the current EKS cluster
kubeconfig:
	@CLUSTER_NAME=$$(terraform -chdir=$(TF_EKS_DIR) output -raw cluster_name); \
	REGION=$$(terraform -chdir=$(TF_EKS_DIR) output -raw cluster_region); \
	aws eks update-kubeconfig --name $$CLUSTER_NAME --region $$REGION

## Quick sanity: show nodes and system pods
cluster-status:
	kubectl get nodes
	kubectl get pods -A

## Install/upgrade the myapp Helm release into the cluster
app-up:
	terraform -chdir=$(TF_APP_DIR) init
	terraform -chdir=$(TF_APP_DIR) apply -target=helm_release.myapp -auto-approve
	kubectl -n $(NAMESPACE) get deploy,svc,pods -l app.kubernetes.io/name=myapp -o wide

## Remove the myapp Helm release from the cluster
app-down:
	terraform -chdir=$(TF_APP_DIR) destroy -target=helm_release.myapp -auto-approve || true

## Port-forward myapp Service to localhost:$(PORT)
port-forward:
	kubectl -n $(NAMESPACE) port-forward svc/myapp $(PORT):80

## One-shot demo: create cluster, deploy app, port-forward
demo-start: cluster-up app-up port-forward

## One-shot teardown: remove app, destroy cluster
demo-stop: app-down cluster-down

