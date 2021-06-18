# syntax=docker/dockerfile:1

# This is a Dockerfile for building release images.
#
# The base Dockerfile is used by operator-sdk, so we can't use that name.
# That Dockerfile merely copies a binary that has been built outside Docker,
# which is useful for development work because it means the build shares the Go
# module cache from your local machine.
#
# In contrast, this file builds the binary inside Docker so it's more
# self-contained and doesn't require operator-sdk or external steps.
# The downside is that there's no good way to share the local Go module cache
# without messing up file permissions, since the Docker container doesn't run as
# your actual user.

FROM golang:1.15 AS build

ENV GO111MODULE=on
ENV GOPROXY direct
ENV GOBIN /go/bin
ENV GOMODCACHE /root/.cache/go-build
WORKDIR /go/src/planetscale.dev/vitess-operator
COPY . /go/src/planetscale.dev/vitess-operator
RUN --mount=type=cache,target=/root/.cache/go-build go env -w GOPROXY=direct && go env -w GOBIN="/go/bin" && go env -w GOMODCACHE="/root/.cache/go-build" \
  && make generate generate-operator-yaml && make generate generate-operator-yaml && go install /go/src/planetscale.dev/vitess-operator/cmd/manager
