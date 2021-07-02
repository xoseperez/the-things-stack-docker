variable "TAG" { default = "latest" }
variable "VERSION" { default = "latest" }
variable "MAJOR" { default = "latest" }

group "default" {
    targets = ["raspberrypi"]
}

target "raspberrypi" {
    tags = [
        "docker.io/xoseperez/the-things-stack:${TAG}",
        "docker.io/xoseperez/the-things-stack:${MAJOR}",
        "docker.io/xoseperez/the-things-stack:${VERSION}",
        "docker.io/xoseperez/the-things-stack:latest",
    ]
    platforms = ["linux/arm/v7", "linux/arm64", "linux/amd64"]
}
