variable "hostname" {
  type    = string
  default = "test.com"
}

variable "location" {
  type    = string
  default = "North Central US"
}

variable "prefix" {
  type    = string
  default = "cgdemo"
}

variable "tags" {
  description = "Default tags to apply to all resources."
  type        = map(any)
}

