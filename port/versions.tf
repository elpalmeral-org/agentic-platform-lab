# Port como código (ADR 0017). Estado en S3; bucket y región por -backend-config (no van al repo).
terraform {
  required_version = ">= 1.10"

  required_providers {
    port = {
      source  = "port-labs/port-labs"
      version = "~> 2.33"
    }
  }

  backend "s3" {
    key                  = "port/terraform.tfstate"
    workspace_key_prefix = "port/workspaces" # dentro de port/*: lo único que permite el rol de CI
    use_lockfile         = true              # bloqueo nativo de S3, sin DynamoDB
    encrypt              = true
  }
}

# Credenciales por variables de entorno: PORT_CLIENT_ID y PORT_CLIENT_SECRET
provider "port" {
  base_url = "https://api.getport.io" # región EU
}
