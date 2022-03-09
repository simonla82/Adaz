locals {
  domain    = yamldecode(file(var.domain_config_file))
  public_ip = chomp(data.http.public_ip.body)
}