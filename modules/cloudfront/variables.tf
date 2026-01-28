variable "alb_dns_name" {
    type = string
}
variable "price_class" {
  type = string
}
variable "origin_protocol_policy" {
  type = string
}
variable "allowed_methods" {
  type = list(string)
}
variable "origin_ssl_protocols" {
  type = list(string)
}