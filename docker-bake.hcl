variable "TAG" { default = "latest" }
variable "VERSION" { default = "latest" }
variable "MAJOR" { default = "latest" }
variable "BUILD_DATE" { default = "" }
variable "REGISTRY" { default = "xoseperez/the-things-stack" }

group "default" {
    targets = ["stack"]
}

target "stack" {
    tags = [
        "${REGISTRY}:${MAJOR}",
        "${REGISTRY}:${VERSION}",
        "${REGISTRY}:${TAG}",
        "${REGISTRY}:latest",
    ]
    args = {
        "TAG" = "${TAG}",
        "BUILD_DATE" = "${BUILD_DATE}"
    }
    platforms = ["linux/arm/v7", "linux/arm64", "linux/amd64"]
}
