variable "management_region" {
  type        = string
  default     = "us-east-1"
  description = "Home region for Organizations and Control Tower."
}

variable "default_tags" {
  type        = map(string)
  description = "Default tags to apply to resources"
}
