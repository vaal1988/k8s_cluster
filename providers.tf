terraform {
  required_providers {
    libvirt = {
      source = "multani/libvirt"
      version = "0.6.3-1+4"
    }
    # docker = {
    #   source = "kreuzwerker/docker"
    #   version = "2.14.0"
    # }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# provider "docker" {
#   host = "unix:///var/run/docker.sock"
# }