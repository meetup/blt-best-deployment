PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TARGET_DIR=$(PROJECT_DIR)target

SHELL = /bin/bash

CI_BUILD_NUMBER ?= $(USER)-snapshot
VERSION ?= $(CI_BUILD_NUMBER)
DATE=$(shell date +%Y-%m-%dT%H_%M_%S)

# Deployment target information
# Override these in an env.
ZONE ?= us-east1-b
CLUSTER ?= your-cluster
PROJECT ?= your-project

# Tells our deployment to fail or not.
FAIL_REQUEST ?= true

help:
	@echo Public targets:
	@grep -E '^[^_][^_][a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo "Private targets: (use at own risk)"
	@grep -E '^__[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[35m%-20s\033[0m %s\n", $$1, $$2}'

# required for list
no_op__:

version: ## Convenience for knowing version in current context.
	@echo $(VERSION)

deploy: __get-credentials __deploy-only ## Does full deployment.

__deploy-only: ## Does deployment without setting creds. (current kubectl ctx)
	@kubectl apply -f infra/deployment-ns.yaml
	@kubectl apply -f infra/deployment-cm.yaml

# Perform our deployment.
	@DATE=$(DATE) \
		FAIL_REQUEST=$(FAIL_REQUEST) \
		envtpl < infra/deployment-deploy.yaml | kubectl apply -f -

# Check on deployment with a 1 min timeout (new replicas never came up)
#  if we timeout rollback and error out.
	@timeout 1m kubectl rollout status deploy deployment --namespace best || { \
		if [ "$$?" == "124" ]; then \
			echo "Deployment timed out"; \
			kubectl rollout undo deploy deployment --namespace best; \
		fi; \
		false; \
	}

__get-credentials: ## Set kubectl ctx to curent cluster config.
	@gcloud container clusters get-credentials \
		--zone $(ZONE) \
		--project $(PROJECT) \
		$(CLUSTER) 2> /dev/null
