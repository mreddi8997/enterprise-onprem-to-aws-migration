variable "db_username" {
  type        = string
  description = "Master username for the PostgreSQL database"
  default     = "appuser"
}

variable "db_password" {
  type        = string
  description = "Master password for the PostgreSQL database of your choice"
  sensitive   = true
}
