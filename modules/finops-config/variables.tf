variable "management_region" {
  type        = string
  default     = "us-east-1"
  description = "Home region for Config and related resources."
}

variable "default_tags" {
  type        = map(string)
  description = "Default tags to apply to resources"
}
