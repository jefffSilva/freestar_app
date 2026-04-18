terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }

  # Bucket/prefix are supplied via init -backend-config (CI) or a backend.hcl file (local).
  backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region  = var.region
}
