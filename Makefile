SHELL := /bin/bash
.DEFAULT_GOAL := help

CHARTS      := payflow corebank postgres redis
RENDERED    := rendered
K8S_VERSION := 1.37.0
CRD_SCHEMAS := https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json
TF          := terraform -chdir=terraform

.PHONY: help
help: ## List targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-16s %s\n", $$1, $$2}'

.PHONY: tools
tools: ## Check that the CLI tools are installed
	@for t in docker kind kubectl helm terraform kubeconform; do \
		command -v $$t >/dev/null && echo "ok      $$t" || echo "missing $$t"; \
	done

## Local cluster

.PHONY: up
up: ## Create the kind cluster, install Argo CD and bootstrap the root app
	$(TF) init -input=false
	$(TF) apply -auto-approve

.PHONY: down
down: ## Destroy the cluster
	$(TF) destroy -auto-approve

.PHONY: status
status: ## Argo CD applications and pods
	kubectl -n argocd get applications
	@for ns in data payflow corebank; do echo "--- $$ns"; kubectl -n $$ns get pods; done

.PHONY: passwords
passwords: ## Print the generated admin passwords
	@echo "argocd   admin / $$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d)"
	@echo "grafana  admin / $$($(TF) output -raw grafana_admin_password)"
	@echo "corebank admin@corebank.local / $$($(TF) output -raw corebank_admin_password)"

## Checks (same as CI)

.PHONY: lint
lint: ## helm lint every chart
	@for c in $(CHARTS); do helm lint charts/$$c --strict || exit 1; done

.PHONY: render
render: ## Render charts and kustomizations into rendered/
	@rm -rf $(RENDERED) && mkdir -p $(RENDERED)
	@for c in $(CHARTS); do helm template $$c charts/$$c --namespace $$c > $(RENDERED)/$$c.yaml || exit 1; done
	@kubectl kustomize monitoring > $(RENDERED)/monitoring.yaml

.PHONY: validate
validate: render ## Validate rendered manifests and Argo CD apps with kubeconform
	kubeconform -strict -summary -kubernetes-version $(K8S_VERSION) \
		-schema-location default -schema-location '$(CRD_SCHEMAS)' \
		$(RENDERED) apps

.PHONY: tf-check
tf-check: ## terraform fmt and validate (no cluster needed)
	terraform fmt -check -recursive terraform
	$(TF) init -backend=false -input=false
	$(TF) validate

.PHONY: check
check: lint validate tf-check ## Everything CI runs
