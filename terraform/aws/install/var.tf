variable "public-ip" {
  type = map(string)
}

variable "private-ip" {
  type = map(string)
}

variable "domain"{
  type = string
}

variable "cluster" {
  type = string
}

// module.cluster-spoke-1.private_ip
variable "cluster-nodes" {
  type = map(string)
}

// random_string.protocols.result
variable "cluster_pwd" {
 type = string
}

variable "sys_psw" {
  type = string
}

variable "acc_psw" {
  type = string
}

variable "leaf" {
  type = bool
}

variable "hub" {
  type = map(string)
  default = {}
}

//==
variable "CLUSTER_USER" {
  default = "cluster"
}

variable "GW_USER" {
  default = "gw"
}

variable "SYS_LEAF" {
  default = "sys_leaf"
}

variable "DOMAIN_LEAF" {
  default = "leaf"
}

variable "SYS_ADMIN" {
  default = "sys_admin"
}

variable "DOMAIN_JS_ADMIN" {
  default = "jetstream_admin"
}

variable "DOMAIN_ADMIN" {
  default = "admin"
}

variable "DOMAIN_CLIENT" {
  default = "client"
}

variable "DOMAIN_PUBLIC" {
  default = "public"
}