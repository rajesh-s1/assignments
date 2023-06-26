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