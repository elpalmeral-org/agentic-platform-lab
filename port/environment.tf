# environment · adoptado de la plantilla (ADR 0018) y ampliado.
# Sus relaciones de plantilla (aws_account, argo_cluster, k8s_cluster) no se declaran aquí: el
# proveedor conserva las relaciones no gestionadas.
resource "port_blueprint" "environment" {
  identifier            = "environment"
  title                 = "Environment"
  icon                  = "Environment"
  description           = "Entornos del agentic-platform-lab: dev, staging y prod (un namespace meridian-<entorno> por servicio)"
  force_delete_entities = false

  properties = {
    number_props = {
      order = {
        title       = "Orden"
        description = "Posición en la cadena de promoción (1 = dev)"
      }
    }
    string_props = {
      promotion_gate = {
        title       = "Cómo se llega"
        description = "Puerta de promoción que exige la plataforma (gitops-ok + esto)"
        enum        = ["auto-merge", "PR fusionado por una persona", "aprobación del entorno + PR"]
        enum_colors = {
          "auto-merge"                   = "green"
          "PR fusionado por una persona" = "yellow"
          "aprobación del entorno + PR"  = "red"
        }
      }
      dora_label = {
        title       = "Etiqueta DORA"
        description = "Valor de deployment.environment para este entorno (los agregados DORA filtran por Production)"
        enum        = ["Development", "Staging", "Production"]
      }
    }
  }

  mirror_properties = {
    argoCluster = {
      path  = "argo_cluster.server"
      title = "Argo Cluster"
    }
  }
}

locals {
  environments = {
    dev     = { title = "Development", order = 1, gate = "auto-merge", dora = "Development" }
    staging = { title = "Staging", order = 2, gate = "PR fusionado por una persona", dora = "Staging" }
    prod    = { title = "Production", order = 3, gate = "aprobación del entorno + PR", dora = "Production" }
  }
}

# staging se importa de la plantilla (imports.tf); dev y prod se crean
resource "port_entity" "dev" {
  blueprint  = port_blueprint.environment.identifier
  identifier = "dev"
  title      = local.environments.dev.title
  properties = {
    number_props = { order = local.environments.dev.order }
    string_props = { promotion_gate = local.environments.dev.gate, dora_label = local.environments.dev.dora }
  }

  lifecycle {
    # Port devuelve las relaciones de plantilla vacías (null) y el plan querría "quitarlas" siempre.
    # No se gestionan desde aquí: las rellenarán el exportador de Kubernetes y Argo CD (F3.3).
    ignore_changes = [relations]
  }
}

resource "port_entity" "staging" {
  blueprint  = port_blueprint.environment.identifier
  identifier = "staging"
  title      = local.environments.staging.title
  properties = {
    number_props = { order = local.environments.staging.order }
    string_props = { promotion_gate = local.environments.staging.gate, dora_label = local.environments.staging.dora }
  }

  lifecycle {
    # Port devuelve las relaciones de plantilla vacías (null) y el plan querría "quitarlas" siempre.
    # No se gestionan desde aquí: las rellenarán el exportador de Kubernetes y Argo CD (F3.3).
    ignore_changes = [relations]
  }
}

resource "port_entity" "prod" {
  blueprint  = port_blueprint.environment.identifier
  identifier = "prod"
  title      = local.environments.prod.title
  properties = {
    number_props = { order = local.environments.prod.order }
    string_props = { promotion_gate = local.environments.prod.gate, dora_label = local.environments.prod.dora }
  }

  lifecycle {
    # Port devuelve las relaciones de plantilla vacías (null) y el plan querría "quitarlas" siempre.
    # No se gestionan desde aquí: las rellenarán el exportador de Kubernetes y Argo CD (F3.3).
    ignore_changes = [relations]
  }
}
