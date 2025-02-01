target "_common" {
  args = {
    GO_VERSION = "1.23"
  }
  labels = {
    "org.opencontainers.image.source" = "https://github.com/fedev521/demos/grpc-lb"
  }
  platforms = ["linux/amd64"]
  target    = "production"
}

variable "REPO" {
  default = "docker.io/garzelli95"
}

variable "PREFIX" {
  default = "grpc-lb-"
}

group "default" {
  targets = ["client", "server"]
}

target "client" {
  inherits = ["_common"]
  tags     = ["${REPO}/demos:${PREFIX}client"]
  args = {
    PROGRAM        = "${PREFIX}client"
    PROGRAM_FOLDER = "client"
  }
}

target "server" {
  inherits = ["_common"]
  tags     = ["${REPO}/demos:${PREFIX}server"]
  args = {
    PROGRAM        = "${PREFIX}server"
    PROGRAM_FOLDER = "server"
  }
}
