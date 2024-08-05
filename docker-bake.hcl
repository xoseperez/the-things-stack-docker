variable "TAG" { default = "latest" }
variable "VERSION" { default = "latest" }
variable "BUILD_DATE" { default = "" }
variable "REGISTRY" { default = "xoseperez/the-things-stack" }
variable "REMOTE_TAG" { default = "3.31.1" }

group "default" {
    targets = ["armv7hf", "aarch64", "amd64", "armv7hf-lite", "aarch64-lite", "amd64-lite"]
}

target "armv7hf" {
    tags = ["${REGISTRY}:armv7hf-latest"]
    dockerfile = "Dockerfile"
    args = {
        "ARCH" = "armv7hf",
        "CFSSL_ARCH" = "arm",
        "REMOTE_TAG" = "${REMOTE_TAG}",
        "TAG" = "${TAG}",
        "VERSION" = "${VERSION}",
        "BUILD_DATE" = "${BUILD_DATE}"
    }
    platforms = ["linux/arm/v7"]
}

target "aarch64" {
    tags = ["${REGISTRY}:aarch64-latest"]
    dockerfile = "Dockerfile"
    args = {
        "ARCH" = "aarch64",
        "CFSSL_ARCH" = "arm",
        "REMOTE_TAG" = "${REMOTE_TAG}",
        "TAG" = "${TAG}",
        "VERSION" = "${VERSION}",
        "BUILD_DATE" = "${BUILD_DATE}"
    }
    platforms = ["linux/arm64"]
}

target "amd64" {
    tags = ["${REGISTRY}:amd64-latest"]
    dockerfile = "Dockerfile"
    args = {
        "ARCH" = "amd64",
        "CFSSL_ARCH" = "amd64",
        "REMOTE_TAG" = "${REMOTE_TAG}",
        "TAG" = "${TAG}",
        "VERSION" = "${VERSION}",
        "BUILD_DATE" = "${BUILD_DATE}"
    }
    platforms = ["linux/amd64"]
}

target "armv7hf-lite" {
    tags = ["${REGISTRY}:armv7hf-latest-lite"]
    dockerfile = "Dockerfile.lite"
    args = {
        "ARCH" = "armv7hf",
        "CFSSL_ARCH" = "arm",
        "REMOTE_TAG" = "${REMOTE_TAG}",
        "TAG" = "${TAG}",
        "VERSION" = "${VERSION}",
        "BUILD_DATE" = "${BUILD_DATE}"
    }
    platforms = ["linux/arm/v7"]
}

target "aarch64-lite" {
    tags = ["${REGISTRY}:aarch64-latest-lite"]
    dockerfile = "Dockerfile.lite"
    args = {
        "ARCH" = "aarch64",
        "CFSSL_ARCH" = "arm",
        "REMOTE_TAG" = "${REMOTE_TAG}",
        "TAG" = "${TAG}",
        "VERSION" = "${VERSION}",
        "BUILD_DATE" = "${BUILD_DATE}"
    }
    platforms = ["linux/arm64"]
}

target "amd64-lite" {
    tags = ["${REGISTRY}:amd64-latest-lite"]
    dockerfile = "Dockerfile.lite"
    args = {
        "ARCH" = "amd64",
        "CFSSL_ARCH" = "amd64",
        "REMOTE_TAG" = "${REMOTE_TAG}",
        "TAG" = "${TAG}",
        "VERSION" = "${VERSION}",
        "BUILD_DATE" = "${BUILD_DATE}"
    }
    platforms = ["linux/amd64"]
}

