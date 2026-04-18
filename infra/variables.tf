variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "Default GCP region."
  type        = string
  default     = "us-central1"
}

variable "name_prefix" {
  description = "Prefix for deployed resources."
  type        = string
  default     = "freestar"
}

variable "cloud_run_service_name" {
  description = "Cloud Run service name (must match GitHub Actions CLOUD_RUN_SERVICE_NAME). Required when enable_load_balancer is true."
  type        = string
  default     = "freestar-hello"
}

variable "enable_load_balancer" {
  description = "Provision external HTTP(S) LB + serverless NEG to Cloud Run. Set false until the Cloud Run service exists (NEG creation requires it)."
  type        = bool
  default     = false
}

variable "lb_ssl_domains" {
  description = "Optional domains for Google-managed HTTPS on the LB (DNS must resolve to load_balancer_ip)."
  type        = list(string)
  default     = []
}
