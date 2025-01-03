terraform {
  required_providers {
    keycloak = {
      source = "keycloak/keycloak"
      version = "4.5.0"
    }
  }
}

provider "keycloak" {
  client_id = "admin-cli"
  username = "admin"
  password = var.admin_pass
  url = "https://keycloak.local"
  initial_login = true
}