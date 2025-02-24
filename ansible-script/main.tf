provider "jenkins" {
  server_url = "http://15.206.229.210:8080"
  username   = var.username
  password   = var.password
}

terraform {
  required_providers {
    jenkins = {
      source  = "taiidani/jenkins"
      version = "0.10.2"
    }
  }
}

variable "username" {
  type    = string
  default = "sarath"
}

variable "password" {
  type    = string
  default = "Kumar@123"
}

variable "branch" {
  type    = string
  default = "main"
}

variable "disabled" {
  type    = string
  default = "false"
}

variable "create_credential" {
  type    = bool
  default = true
}

locals {
  services = [
    "https://bitbucket.org/abjayondigitalselfservice/usage-service"
  ]
}

resource "jenkins_job" "services" {
  count = length(local.services)

  name = replace(format("%s-%s", replace(basename(local.services[count.index]), ".git", ""), timestamp()), "[^a-zA-Z0-9_-]", "_")

  template = templatefile("${path.module}/job.xml", {
    repo            = local.services[count.index]
    branch          = var.branch
    disabled        = var.disabled
    parameter1      = var.parameter1
    parameter2      = var.parameter2
    secret_parameter = var.secret_parameter
  })
}
