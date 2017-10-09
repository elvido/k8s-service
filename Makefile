# Copyright 2017 Ralf Hofmann. All rights reserved.
# Use of this source code is governed by a MIT-style
# license that can be found in the LICENSE file.

APP=k8s-service
PROJECT=github.com/elvido/k8s-service
REGISTRY?=docker.io/elvido
CA_DIR?=certs

# Use the 0.0.0 tag for testing, it shouldn't clobber any release builds
RELEASE?=0.0.5
GOOS?=linux
GOARCH?=amd64

K8S_SERVICE_LOCAL_HOST?=0.0.0.0
K8S_SERVICE_LOCAL_PORT?=8080
K8S_SERVICE_LOG_LEVEL?=0
K8S_SERVICE_EVENTS_DEFINITION?="/events.json"

# Namespace: dev, prod, release, cte, username ...
NAMESPACE?=dev

# Infrastructure: dev, stable, test ...
INFRASTRUCTURE?=dev
VALUES?=values-${INFRASTRUCTURE}

CONTAINER_IMAGE?=${REGISTRY}/${APP}
CONTAINER_NAME?=${APP}-${NAMESPACE}

REPO_INFO=$(shell git config --get remote.origin.url)

ifndef COMMIT
	COMMIT := git-$(shell git rev-parse --short HEAD)
endif

BUILDTAGS=

.PHONY: all
all: build

.PHONY: vendor
vendor: clean bootstrap
	dep ensure

.PHONY: build
build: vendor test certs
	@echo "+ $@"
	@CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} go build -a -installsuffix cgo \
		-ldflags "-s -w -X ${PROJECT}/pkg/version.RELEASE=${RELEASE} -X ${PROJECT}/pkg/version.COMMIT=${COMMIT} -X ${PROJECT}/pkg/version.REPO=${REPO_INFO}" \
		-o bin/${GOOS}-${GOARCH}/${APP} ${PROJECT}/cmd
	docker build --pull -t $(CONTAINER_IMAGE):$(RELEASE) .

.PHONY: certs
certs:
ifeq ("$(wildcard $(CA_DIR)/ca-certificates.crt)","")
	@echo "+ $@"
	@docker run --name ${CONTAINER_NAME}-certs -d alpine:edge sh -c "apk --update upgrade && apk add ca-certificates && update-ca-certificates"
	@docker wait ${CONTAINER_NAME}-certs
	@mkdir -p ${CA_DIR}
	@docker cp ${CONTAINER_NAME}-certs:/etc/ssl/certs/ca-certificates.crt ${CA_DIR}
	@docker rm -f ${CONTAINER_NAME}-certs
endif

.PHONY: push
push: build
	@echo "+ $@"
	@docker push $(CONTAINER_IMAGE):$(RELEASE)

.PHONY: run
run: build
	@echo "+ $@"
	@docker run --name ${CONTAINER_NAME} -p ${K8S_SERVICE_LOCAL_PORT}:${K8S_SERVICE_LOCAL_PORT} \
		-e "K8S_SERVICE_LOCAL_HOST=${K8S_SERVICE_LOCAL_HOST}" \
		-e "K8S_SERVICE_LOCAL_PORT=${K8S_SERVICE_LOCAL_PORT}" \
		-e "K8S_SERVICE_LOG_LEVEL=${K8S_SERVICE_LOG_LEVEL}" \
		-e "K8S_SERVICE_EVENTS_DEFINITION=${K8S_SERVICE_EVENTS_DEFINITION}" \
		-d $(CONTAINER_IMAGE):$(RELEASE)
	@sleep 1
	@docker logs ${CONTAINER_NAME}

HAS_RUNNED := $(shell docker ps | grep ${CONTAINER_NAME})
HAS_EXITED := $(shell docker ps -a | grep ${CONTAINER_NAME})

.PHONY: logs
logs:
	@echo "+ $@"
	@docker logs ${CONTAINER_NAME}

.PHONY: stop
stop:
ifdef HAS_RUNNED
	@echo "+ $@"
	@docker stop ${CONTAINER_NAME}
endif

.PHONY: start
start: stop
	@echo "+ $@"
	@docker start ${CONTAINER_NAME}

.PHONY: rm
rm:
ifdef HAS_EXITED
	@echo "+ $@"
	@docker rm ${CONTAINER_NAME}
endif

.PHONY: deploy
deploy: push
	helm upgrade ${CONTAINER_NAME} -f charts/${VALUES}.yaml charts --kube-context ${INFRASTRUCTURE} --namespace ${NAMESPACE} --version=${RELEASE} -i --wait

GO_LIST_FILES=$(shell go list ${PROJECT}/... | grep -v vendor)

.PHONY: fmt
fmt:
	@echo "+ $@"
	@go list -f '{{if len .TestGoFiles}}"gofmt -s -l {{.Dir}}"{{end}}' ${GO_LIST_FILES} | xargs -L 1 sh -c

.PHONY: lint
lint: bootstrap
	@echo "+ $@"
	@go list -f '{{if len .TestGoFiles}}"golint -min_confidence=0.85 {{.Dir}}/..."{{end}}' ${GO_LIST_FILES} | xargs -L 1 sh -c

.PHONY: vet
vet:
	@echo "+ $@"
	@go vet ${GO_LIST_FILES}

.PHONY: test
test: vendor fmt lint vet
	@echo "+ $@"
	@go test -v -race -cover -tags "$(BUILDTAGS) cgo" ${GO_LIST_FILES}

.PHONY: cover
cover:
	@echo "+ $@"
	@> coverage.txt
	@go list -f '{{if len .TestGoFiles}}"go test -coverprofile={{.Dir}}/.coverprofile {{.ImportPath}} && cat {{.Dir}}/.coverprofile  >> coverage.txt"{{end}}' ${GO_LIST_FILES} | xargs -L 1 sh -c

.PHONY: clean
clean: stop rm
	@rm -f bin/${GOOS}-${GOARCH}/${APP}

HAS_DEP := $(shell command -v dep;)
HAS_LINT := $(shell command -v golint;)

.PHONY: bootstrap
bootstrap:
ifndef HAS_DEP
	go get -u github.com/golang/dep/cmd/dep
endif
ifndef HAS_LINT
	go get -u github.com/golang/lint/golint
endif
