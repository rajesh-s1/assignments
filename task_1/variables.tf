#RESOURCE GROUP NAME

variable "rg_name" {
  description = "Resource group name, all resource go here"
  type = string
  default = "k-rg"
}


variable "location" {
  description = "location to deploy all resources"
  type = string
  default = "South India"
}

locals {
  tiers = {
    "fe" = "10.1.1.0/24"
    "be" = "10.1.2.0/24"
    "db" = "10.1.3.0/24"
  }
}