terraform {
  required_version = "~> 1.15"

  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "~> 2026.8.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}