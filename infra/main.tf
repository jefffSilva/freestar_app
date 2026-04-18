# Modules are loaded from the modules repo on GitHub. Replace YOUR_GITHUB_ORG.
# If the repo is named differently (e.g. freestart_modules), change that path segment too.
# Pin ?ref= to a tag or commit for production.
module "network" {
  source = "git::https://github.com/YOUR_GITHUB_ORG/freestar_modules.git//network?ref=main"

  project_id  = var.project_id
  region      = var.region
  name_prefix = var.name_prefix
}

module "security" {
  source = "git::https://github.com/YOUR_GITHUB_ORG/freestar_modules.git//security?ref=main"

  project_id  = var.project_id
  name_prefix = var.name_prefix
}

module "secrets" {
  source = "git::https://github.com/YOUR_GITHUB_ORG/freestar_modules.git//secrets?ref=main"

  project_id                    = var.project_id
  name_prefix                   = var.name_prefix
  runtime_service_account_email = module.security.runtime_service_account_email
}

module "load_balancer" {
  count = var.enable_load_balancer ? 1 : 0

  source = "git::https://github.com/YOUR_GITHUB_ORG/freestar_modules.git//load_balancer?ref=main"

  project_id             = var.project_id
  region                 = var.region
  name_prefix            = var.name_prefix
  cloud_run_service_name = var.cloud_run_service_name
  ssl_domains            = var.lb_ssl_domains
}
