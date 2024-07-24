variable "region" {
  description = "AWS region"
  type        = string
}

variable "source_cidr" {
  description = "CIDR block of the source database"
  type        = string
}

variable "source_db_user" {
  description = "Username for the source database"
  type        = string
}

variable "source_db_password" {
  description = "Password for the source database"
  type        = string
  sensitive   = true
}

variable "source_db_host" {
  description = "Hostname of the source database"
  type        = string
}

variable "source_db_port" {
  description = "Port of the source database"
  type        = number
}

variable "source_db_name" {
  description = "Name of the source database"
  type        = string
}

variable "target_db_user" {
  description = "Username for the target database"
  type        = string
}

variable "target_db_password" {
  description = "Password for the target database"
  type        = string
  sensitive   = true
}

variable "target_db_host" {
  description = "Hostname of the target database"
  type        = string
}

variable "target_db_port" {
  description = "Port of the target database"
  type        = number
  default     = 3306
}

variable "target_db_name" {
  description = "Name of the target database"
  type        = string
}
