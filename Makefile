.PHONY: build release-build unit-test integration-test generate generate-operator-yaml push-only push

IMAGE_TAG:=ubi7

IMAGE:=planetscale/vitess-operator

IMAGE_NAME:=$(IMAGE)

# Enable Go modules
export GO111MODULE=on
export GOPROXY=direct
export GOBIN=/go/bin
export DOCKER_BUILDKIT=1

# Release build is slow but self-contained (doesn't depend on anything in your
# local machine). We use this for automated builds that we publish.
release-build:
	DOCKER_BUILDKIT=1 docker build -f build/Dockerfile.release.builder -t $(IMAGE_NAME)-builder:builder-$(IMAGE_TAG) .
	DOCKER_BUILDKIT=1 docker build -f build/Dockerfile.release -t $(IMAGE_NAME):$(IMAGE_TAG) .

# Hack GOPATH: this works only if $GOPATH/src/planetscale.dev/vitess-operator computes to the current directory.
# operator-sdk needs GOPATH to be set.
export GOPATH=$(shell realpath ../../..)

generate:
	go env -w GOPROXY=direct && go run github.com/operator-framework/operator-sdk/cmd/operator-sdk generate k8s
	go env -w GOPROXY=direct && go run sigs.k8s.io/controller-tools/cmd/controller-gen crd:trivialVersions=true,maxDescLen=0 paths="./pkg/apis/planetscale/v2" output:crd:artifacts:config=./deploy/crds
	find deploy/crds -name '*.yaml' | xargs go run ./cmd/trim-crd
	go env -w GOPROXY=direct && go run github.com/ahmetb/gen-crd-api-reference-docs -api-dir ./pkg/apis -config docs/api/config.json -template-dir docs/api/template -out-file docs/api/index.html

generate-operator-yaml:
	go env -w GOPROXY=direct && go run sigs.k8s.io/kustomize build ./deploy > deploy/operator.yaml
