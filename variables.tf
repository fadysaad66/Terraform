variable "client_id" {
    type = string
    description = "this is the client id"
  
}
variable "client_secret" {
    type = string
    default = "this is the client secret"
  
}
variable "tenant_id" {
    type = string
    description = "this is the tenant id"
  
}

variable "subscription_id" {
  
  type = string
  description = "this is the subscription id "
}

variable "admin_password" {
    type = string
    description = "this is the password for the vm user "
  
}
 