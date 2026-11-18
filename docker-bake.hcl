# Builds both images, for all platforms:
#   docker buildx bake
# For this machine only, loaded into the local Docker:
#   docker buildx bake --load --set '*.platform=linux/amd64'

variable "REGISTRY" { default = "xoseperez/the-things-stack" }
# The upstream release this commit is prepared for. Release tags must name it:
# v<UPSTREAM_VERSION>-r<n>. The release workflow checks they match.
variable "UPSTREAM_VERSION" { default = "3.37.0" }
variable "VERSION" { default = "dev" }
# Comma-separated extra tags; CI passes "X.Y.Z,X.Y,X,latest" for the newest release.
variable "EXTRA_TAGS" { default = "" }
variable "REVISION" { default = "" }

# The image tags, with SUFFIX added. The lite image's "latest" is plain "lite".
function "image_tags" {
  params = [suffix]
  result = concat(
    ["${REGISTRY}:${VERSION}${suffix}"],
    [for t in split(",", EXTRA_TAGS) :
      (t == "latest" && suffix != "" ? "${REGISTRY}:lite" : "${REGISTRY}:${t}${suffix}") if t != ""]
  )
}

group "default" {
  targets = ["stack", "lite"]
}

target "_common" {
  context   = "."
  platforms = ["linux/amd64", "linux/arm64", "linux/arm/v7"]
  args = {
    UPSTREAM_VERSION = UPSTREAM_VERSION
    VERSION          = VERSION
  }
  labels = {
    "org.opencontainers.image.source"    = "https://github.com/xoseperez/the-things-stack-docker"
    "org.opencontainers.image.version"   = VERSION
    "org.opencontainers.image.revision"  = REVISION
    "org.opencontainers.image.licenses"  = "Apache-2.0"
    "org.opencontainers.image.base.name" = "docker.io/thethingsnetwork/lorawan-stack:${UPSTREAM_VERSION}"
  }
}

target "stack" {
  inherits   = ["_common"]
  dockerfile = "Dockerfile"
  tags       = image_tags("")
  labels = {
    "org.opencontainers.image.title" = "The Things Stack"
  }
}

target "lite" {
  inherits   = ["_common"]
  dockerfile = "Dockerfile.lite"
  tags       = image_tags("-lite")
  labels = {
    "org.opencontainers.image.title" = "The Things Stack (lite)"
  }
}
