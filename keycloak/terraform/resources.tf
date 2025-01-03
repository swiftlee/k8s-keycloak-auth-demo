# Create a dedicated realm for application
resource "keycloak_realm" "app_realm" {
  realm             = "k8s-demo"
  enabled           = true
  display_name      = "K8s Demo"
  display_name_html = "<div class=\"kc-logo-text\"><span>K8s Demo</span></div>"

  login_theme = "keycloak"
  
  # Configure browser security settings
  security_defenses {
    headers {
      x_frame_options = "SAMEORIGIN"
      content_security_policy = "frame-src 'self'; frame-ancestors 'self'; object-src 'none';"
    }
  }
}

# Create a SAML client
resource "keycloak_saml_client" "backend_saml" {
  realm_id  = keycloak_realm.app_realm.id
  client_id = "k8s-demo-backend"
  name      = "K8s Demo Backend"

  enabled = true
  
  sign_documents          = true
  sign_assertions        = true
  encrypt_assertions     = false
  client_signature_required = true
  force_post_binding     = true

  root_url = "https://k8s-demo.local"
  base_url = "/"
  
  valid_redirect_uris = [
    "https://k8s-demo.local/*"
  ]

  idp_initiated_sso_url_name = "k8s-demo"
  
  master_saml_processing_url = "https://k8s-demo.local/saml/acs"
}

# Configure SAML client authentication flows
resource "keycloak_saml_client_default_scopes" "backend_saml_default_scopes" {
  realm_id  = keycloak_realm.app_realm.id
  client_id = keycloak_saml_client.backend_saml.id

  default_scopes = [
    "role_list",
    "profile",
    "email"
  ]
}

# Create mapper for email
resource "keycloak_saml_user_attribute_protocol_mapper" "email_mapper" {
  realm_id  = keycloak_realm.app_realm.id
  client_id = keycloak_saml_client.backend_saml.id
  name      = "email"

  saml_attribute_name   = "email"
  saml_attribute_name_format = "Basic"
  user_attribute       = "email"
}

# Create mapper for username
resource "keycloak_saml_user_attribute_protocol_mapper" "username_mapper" {
  realm_id  = keycloak_realm.app_realm.id
  client_id = keycloak_saml_client.backend_saml.id
  name      = "username"

  saml_attribute_name   = "username"
  saml_attribute_name_format = "Basic"
  user_attribute       = "username"
}

# Create a test group
resource "keycloak_group" "test_group" {
  realm_id = keycloak_realm.app_realm.id
  name     = "test-group"
}

# Create a test user
resource "keycloak_user" "test_user" {
  realm_id = keycloak_realm.app_realm.id
  username = "testuser"
  enabled  = true

  email      = "testuser@example.com"
  first_name = "Test"
  last_name  = "User"

  initial_password {
    value     = "testpassword"
    temporary = false
  }
}

# For the group mapper
resource "keycloak_saml_user_property_protocol_mapper" "group_mapper" {
  realm_id  = keycloak_realm.app_realm.id
  client_id = keycloak_saml_client.backend_saml.id
  name      = "groups"

  saml_attribute_name = "groups"
  saml_attribute_name_format = "Basic"
  user_property = "groups"
}

# For group membership
resource "keycloak_group_memberships" "test_user_group" {
  realm_id = keycloak_realm.app_realm.id
  group_id = keycloak_group.test_group.id
  members  = [
    keycloak_user.test_user.username
  ]
}