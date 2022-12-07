variable "TAG" { default = "latest" }
variable "REMOTE_TAG" { default = "3.23.0" }
variable "VERSION" { default = "latest" }
variable "BUILD_DATE" { default = "" }
variable "REGISTRY" { default = "xoseperez/the-things-stack" }

group "default" {
    targets = ["armv7hf", "aarch64", "amd64"]
}

target "armv7hf" {
    tags = ["${REGISTRY}:armv7hf-latest"]
    args = {
        "ARCH" = "arm",
        "REMOTE_TAG" = "${REMOTE_TAG}",
        "TAG" = "${TAG}",
        "VERSION" = "${VERSION}",
        "BUILD_DATE" = "${BUILD_DATE}"
    }
    platforms = ["linux/arm/v7"]
}

target "aarch64" {
    tags = ["${REGISTRY}:aarch64-latest"]
    args = {
        "ARCH" = "arm",
        "REMOTE_TAG" = "${REMOTE_TAG}",
        "TAG" = "${TAG}",
        "VERSION" = "${VERSION}",
        "BUILD_DATE" = "${BUILD_DATE}"
    }
    platforms = ["linux/arm64"]
}

target "amd64" {
    tags = ["${REGISTRY}:amd64-latest"]
    args = {
        "ARCH" = "amd64",
        "REMOTE_TAG" = "${REMOTE_TAG}",
        "TAG" = "${TAG}",
        "VERSION" = "${VERSION}",
        "BUILD_DATE" = "${BUILD_DATE}"
    }
    platforms = ["linux/amd64"]
}
