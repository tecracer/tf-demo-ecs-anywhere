variable "region" {
  default = "eu-central-1"
  type    = string
}

variable "instance_type" {
  type    = string
  default = "t2.small"
}

variable "key_name" {
  type = string
}

variable "worker"{
  type = number
  default = 1
}
