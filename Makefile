SHELL :=/bin/bash

# Set PATH (locally) to include local dir for locally downloaded binaries.
LOCAL_PATH := "$(PWD):$(PATH)"

DOCKER_CMD := $(shell PATH=$(LOCAL_PATH) command -v docker 2> /dev/null)
KUBECTL_CMD := $(shell PATH=$(LOCAL_PATH) command -v kubectl 2> /dev/null)
HELM_CMD := $(shell PATH=$(LOCAL_PATH) command -v helm 2> /dev/null)

export PROJECT := $(shell node -p "require('./package.json').name")
export VERSION := $(shell node -p "require('./package.json').version")
export GIT_DEPENDENCY_URL := $(shell node -p "require('./package.json').git_dependency_url")
export IMAGE_NAME := $(DOCKER_USERNAME)/$(PROJECT):$(VERSION)
export DOCKER_SECERT := "dockerhub-registry"

.PHONY: cleanup build build-docker create-docker-secert build-helm build-kubernetes

docker-login: 
	docker login -u $(DOCKER_USERNAME) -p $(DOCKER_PASSWORD) 

create-docker-secert:
	kubectl create secret docker-registry $(DOCKER_SECERT) \
	--docker-server=$(DOCKER_REGISTRY_SERVER) \
	--docker-username=$(DOCKER_USERNAME) \
	--docker-password=$(DOCKER_PASSWORD) \
	--docker-email=$(DOCKER_EMAIL) || true

## Builds Docker Image using Docker cli
build-docker:
	$(MAKE) cleanup 
	$(MAKE) docker-login
	docker run \
		-v $(HOME)/.docker/config.json:/kaniko/.docker/config.json \
        gcr.io/kaniko-project/executor:latest \
        --dockerfile "Dockerfile" \
		--destination "${IMAGE_NAME}" \
		--context "${GIT_DEPENDENCY_URL}" \
        --cache=true

## Builds Docker Image using Kubectl cli
build-kubernetes:
	$(MAKE) cleanup
	$(MAKE) create-docker-secert
	envsubst < kaniko.yaml | kubectl apply -f -

## Builds Docker Image using Helm
build-helm:
	$(MAKE) cleanup
	$(MAKE) create-docker-secert
	helm install kaniko kaniko/kaniko \
	--set dockersecertname=$(DOCKER_SECERT) \
	--set context=$(GIT_DEPENDENCY_URL) \
	--set dockerfile=Dockerfile \
	--set destination=$(IMAGE_NAME)

cleanup:
	kubectl delete secret $(DOCKER_SECERT)  || true
	helm uninstall kaniko  || true
	envsubst < kaniko.yaml | kubectl delete -f - || true