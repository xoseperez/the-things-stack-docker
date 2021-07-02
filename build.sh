#!/bin/bash
TAG=$(git rev-parse --short HEAD) VERSION=$(git describe --abbrev=0 --tags) MAJOR=$(git describe --abbrev=0 --tags | cut -d '.' -f1) docker buildx bake $@