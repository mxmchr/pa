terraform {
  backend "s3" {
    bucket = "pa-terraformbuild"
    key    = "build.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    # access_key = var.s3_access_key
    # secret_key = var.s3_secret_key
    # endpoints = { s3 build= var.s3_endpoint }
  }
}