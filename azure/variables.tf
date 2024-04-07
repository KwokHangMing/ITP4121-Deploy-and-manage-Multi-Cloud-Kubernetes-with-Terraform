variable "name" {
  description = "value of the name of the resource"
}


variable "location" {
  description = "The Azure Region in which all resources will be created."
}

variable "image_url" {
  description = "The URL of the Docker image to use for the Kubernetes deployment."
}

variable "db_password" {
  description = "value of the database password"
  type        = string
}

variable "domain_name" {
  description = "value of the domain name"
}

variable "student_id" {
  description = "value of your student id to avoiding conflict error when creating storage account"
}
