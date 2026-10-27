# deployment · adoptado de la plantilla (ADR 0018): UN EVENTO POR PROMOCIÓN.
# Lo crea platform-gitops al fusionar un PR de promoción (F3.4). Sus propiedades de plantilla
# (createdAt, deploymentStatus, environment) alimentan los agregados DORA de service: no se tocan.
# Relaciones de plantilla conservadas: service, github_pull_request (PR de CÓDIGO: lead time).
resource "port_blueprint" "deployment" {
  identifier            = "deployment"
  title                 = "Deployment"
  icon                  = "Deployment"
  description           = "Una promoción a un entorno: se crea al fusionar el PR de promoción en platform-gitops"
  force_delete_entities = false

  properties = {
    string_props = {
      # --- plantilla (DORA) ---
      createdAt = {
        title  = "Deployment Time"
        format = "date-time"
      }
      deploymentStatus = {
        title       = "Deployment Status"
        enum        = ["Success", "Failure", "Pending"]
        enum_colors = { Failure = "red", Pending = "yellow", Success = "green" }
      }
      environment = {
        title       = "Environment"
        enum        = ["Production", "Staging", "Development"]
        enum_colors = { Development = "blue", Production = "green", Staging = "yellow" }
      }
      # --- agentic-platform-lab ---
      tag = {
        title       = "Versión"
        description = "sha-<commit> en dev; X.Y.Z en staging y prod"
      }
      merged_by = {
        title       = "Fusionado por"
        description = "Quién fusionó el PR de promoción (el bot en dev)"
      }
      approved_by = {
        title       = "Entorno aprobado por"
        description = "Revisor del entorno de GitHub (solo prod)"
      }
      promotion_pr_url = {
        title  = "PR de promoción"
        format = "url"
      }
    }
  }

  relations = {
    target_environment = {
      title  = "Entorno"
      target = port_blueprint.environment.identifier
    }
    promotion_pr = {
      title  = "PR de promoción"
      target = "githubPullRequest"
    }
    builds = {
      title  = "Imágenes"
      target = port_blueprint.build.identifier
      many   = true
    }
  }

  mirror_properties = {
    github_lead_time_hours = {
      path  = "github_pull_request.cycle_time_hours"
      title = "Lead Time for Changes (Hours)"
    }
    github_repo_id = {
      path  = "github_pull_request.repository.$identifier"
      title = "GitHub Repository ID"
    }
    promotion_gate = {
      path  = "target_environment.promotion_gate"
      title = "Cómo se llega"
    }
  }
}
