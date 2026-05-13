variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  }

variable "project_name" {
  description = "Name of the project for tagging purposes" 
    type        = string
}

variable "environment" {
  type        = string
}

variable "vpctags" {
  type        = map
  default     = {}
}

variable "igttags" {
  type        = map
  default     = {}
}

variable "public_subnet_cidrs" {
  type        = list
}

variable "public_subnet_tags" {
  type        = map
  default     = {}
}

variable "private_subnet_cidrs" {
  type        = list
}

variable "private_subnet_tags" {
  type        = map
  default     = {}
}

variable  "database_subnet_cidrs" {
  type        = list
}

variable "database_subnet_tags" {
  type        = map
  default     = {}
}

variable "public_route_table_tags" {
  type        = map
  default     = {}
}

variable "private_route_table_tags" {
  type        = map
  default     = {}
}

variable "database_route_table_tags" {
  type        = map
  default     = {}
}

variable "eip_tags" {
  type        = map
  default     = {}
}

variable "nat_gateway_tags" {
  type        = map
  default     = {}
}

variable "is_peering_required" {
  type        = bool
  default     = true
}
