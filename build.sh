#!/bin/bash

export TAG=$(git rev-parse --short HEAD)
export VERSION=$(git describe --abbrev=0 --tags)
export MAJOR=$(git describe --abbrev=0 --tags | cut -d '.' -f1)
export REGISTRY=${REGISTRY:-"xoseperez/the-things-stack"}
export BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

ACTION=$@
time docker buildx bake $ACTION