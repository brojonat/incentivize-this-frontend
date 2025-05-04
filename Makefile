#!/usr/bin/env bash

# Set the shell for make explicitly
SHELL := /bin/bash

# === Configuration ===
# !!! REPLACE THESE PLACEHOLDERS with your actual values !!!
DOCKER_REPO         ?= brojonat  # e.g., gcr.io/your-project or docker.io/your-username
FRONTEND_IMAGE_NAME ?= incentivize-this-frontend
FRONTEND_DOMAIN     ?= incentivizethis.com # Your frontend domain
FRONTEND_K8S_DIR    ?= k8s/prod
FRONTEND_DOCKERFILE ?= k8s/Dockerfile
FRONTEND_APP_DIR    ?= app

# Dynamic variables
GIT_HASH        := $(shell git rev-parse --short HEAD)
FRONTEND_IMG_TAG := $(DOCKER_REPO)/$(FRONTEND_IMAGE_NAME):$(GIT_HASH)

# Load environment variables from a file (optional, but good practice)
# Example: Create a .env.frontend.prod file with DOCKER_REPO=your_repo
#          Or set them in your CI environment
ENV_FILE ?= .env.frontend.prod
define setup_env
	$(eval include $(1))
	$(eval export)
endef

.PHONY: all build-flutter build-docker push-docker deploy-frontend delete-frontend logs-frontend status-frontend restart-frontend

all: deploy-frontend

# === Build Steps ===

# 1. Build Flutter Web App
build-flutter:
	@echo "Building Flutter web application..."
	cd $(FRONTEND_APP_DIR) && flutter build web --release
	@echo "Flutter build complete."

# 2. Build Docker Image
build-docker: build-flutter
	@echo "Building Docker image: $(FRONTEND_IMG_TAG)"
	@# Ensure DOCKER_REPO is set
	@if [ -z "$(DOCKER_REPO)" ] || [ "$(DOCKER_REPO)" = "YOUR_DOCKER_REPO" ]; then \
		echo "Error: DOCKER_REPO is not set or is still the placeholder."; \
		echo "Please set it in $(ENV_FILE) or as an environment variable."; \
		exit 1; \
	fi
	docker build -f $(FRONTEND_DOCKERFILE) -t $(FRONTEND_IMG_TAG) .
	@echo "Docker image built."

# 3. Push Docker Image
push-docker: build-docker
	@echo "Pushing Docker image: $(FRONTEND_IMG_TAG)"
	docker push $(FRONTEND_IMG_TAG)
	@echo "Docker image pushed."


# === Deployment ===

# Deploy Frontend to Kubernetes
deploy-frontend:
	$(call setup_env, $(ENV_FILE))
	@$(MAKE) push-docker
	@echo "Applying frontend deployment with image: $(FRONTEND_IMG_TAG)"
	@# Ensure FRONTEND_DOMAIN is set
	@if [ -z "$(FRONTEND_DOMAIN)" ] || [ "$(FRONTEND_DOMAIN)" = "app.incentivizethis.com" ]; then \
		echo "Warning: FRONTEND_DOMAIN might still be the default placeholder."; \
		echo "Ensure it's correctly set in $(ENV_FILE) or environment for Ingress."; \
	fi
	kustomize build --load-restrictor=LoadRestrictionsNone $(FRONTEND_K8S_DIR) | \
	sed -e "s|{{DOCKER_REPO}}/{{FRONTEND_IMAGE_NAME}}:{{TAG}}|$(FRONTEND_IMG_TAG)|g" \
	    -e "s|{{FRONTEND_DOMAIN}}|$(FRONTEND_DOMAIN)|g" | \
	kubectl apply -f -
	@echo "Frontend deployment applied."

# Delete Frontend from Kubernetes
delete-frontend:
	@echo "Deleting frontend resources from Kubernetes..."
	kubectl delete -k $(FRONTEND_K8S_DIR) --ignore-not-found=true
	@echo "Frontend resources deleted."

# === Operations ===

# View logs for the frontend deployment
logs-frontend:
	@echo "Tailing logs for frontend deployment..."
	kubectl logs -f deployment/incentivize-this-frontend --tail=50

# Check status of the frontend deployment
status-frontend:
	@echo "=== Frontend Deployment Status ==="
	kubectl get deployment incentivize-this-frontend -o wide
	@echo "\n=== Frontend Service Status ==="
	kubectl get service incentivize-this-frontend-service -o wide
	@echo "\n=== Frontend Ingress Status ==="
	kubectl get ingress incentivize-this-frontend-ingress
	@echo "\n=== Frontend Pods Status ==="
	kubectl get pods -l app=incentivize-this-frontend

# Restart the frontend deployment
restart-frontend:
	@echo "Restarting frontend deployment..."
	kubectl rollout restart deployment incentivize-this-frontend
	@echo "Rollout restart initiated."

# Help Target
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build-flutter        Builds the Flutter web application."
	@echo "  build-docker         Builds the Docker image for the frontend."
	@echo "  push-docker          Pushes the Docker image to the registry."
	@echo "  deploy-frontend      Builds, pushes, and deploys the frontend to Kubernetes."
	@echo "  delete-frontend      Deletes the frontend deployment from Kubernetes."
	@echo "  logs-frontend        Tails the logs of the frontend pods."
	@echo "  status-frontend      Shows the status of frontend Kubernetes resources."
	@echo "  restart-frontend     Performs a rollout restart of the frontend deployment."
	@echo "  help                 Shows this help message."
	@echo ""
	@echo "Configuration:"
	@echo "  Set DOCKER_REPO and FRONTEND_DOMAIN via environment variables or in $(ENV_FILE)."

.DEFAULT_GOAL := help
