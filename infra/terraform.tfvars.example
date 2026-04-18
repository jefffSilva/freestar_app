project_id  = "my-gcp-project"
region      = "us-central1"
name_prefix = "freestar"

cloud_run_service_name = "freestar-hello"

# After the first GitHub deploy creates Cloud Run, set true and re-apply to attach the external LB.
enable_load_balancer = false

# Optional HTTPS on the LB (provision DNS A/AAAA to load_balancer_ip output first).
# lb_ssl_domains = ["api.example.com"]

# Modules are sourced from Git in main.tf (freestar_modules repo). Edit YOUR_GITHUB_ORG there,
# or leave the placeholder: CI substitutes it using repository_owner unless you set
# Variable TERRAFORM_MODULES_GITHUB_ORG (e.g. modules repo under a different org).

# CI passes TF_VAR_* via Actions Variables; mirror here for local applies.
