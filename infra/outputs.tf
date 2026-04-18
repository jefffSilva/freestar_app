output "vpc_network_name" {
  value = module.network.network_name
}

output "vpc_connector_name" {
  value = module.network.vpc_connector_name
}

output "runtime_service_account_email" {
  value = module.security.runtime_service_account_email
}

output "sample_secret_id" {
  value = module.secrets.secret_id
}

output "load_balancer_ip" {
  description = "External LB IP (HTTP :80; HTTPS :443 when lb_ssl_domains set). Null if enable_load_balancer is false."
  value       = try(module.load_balancer[0].load_balancer_ip, null)
}

output "load_balancer_http_url" {
  value = try(module.load_balancer[0].http_url, null)
}
