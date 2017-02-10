PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TARGET_DIR=$(PROJECT_DIR)target

VERSION ?= $(CI_BUILD_NUMBER)
DATE=$(shell date +%Y-%m-%dT%H_%M_%S)

# Deployment target information
# Override these in an env.
ZONE ?= us-east1-b
CLUSTER ?= your-cluster
PROJECT ?= your-project

help:
	@echo Public targets:
	@grep -E '^[^_][^_][a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo "Private targets: (use at own risk)"
	@grep -E '^__[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[35m%-20s\033[0m %s\n", $$1, $$2}'

# required for list
no_op__:

# Required for SBT.
version:
	@echo $(VERSION)

deploy: __get-credentials __deploy-only ## Does full deployment.

__deploy-only: ## Does deployment without setting creds. (current kubectl ctx)
	kubectl apply -f infra/best-ns.yaml
	# kubectl apply -f infra/blt-best-sbt-docker-svc.yaml
	# DATE=$(DATE) \
	# 	PUBLISH_TAG=$(PUBLISH_TAG) \
	# 	envtpl < infra/blt-best-sbt-docker-dply.yaml | kubectl apply -f -

__get-credentials: ## Set kubectl ctx to curent cluster config.
	@gcloud container clusters get-credentials \
		--zone $(ZONE) \
		--project $(PROJECT) \
		$(CLUSTER) 2> /dev/null
