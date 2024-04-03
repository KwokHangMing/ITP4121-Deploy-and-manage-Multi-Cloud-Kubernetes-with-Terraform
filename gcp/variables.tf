variable "location" {
  description = "the location of the google cloud"
}

variable "zone" {
  description = "the location zone of the google cloud"
}

variable "project" {
  description = "the project of the google cloud"
}

variable "image_url" {
  description = "image URL for the web apps"
}

variable "domain_name" {
  description = "value of the domain name"
}

variable "password" {
  type        = string
  description = "value of the database password"
}
