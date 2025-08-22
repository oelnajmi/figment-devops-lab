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
