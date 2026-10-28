# F3.6 · "Promocionar" como Workflow de Port (ADR 0021). Sustituye a la acción clásica.
# Decisiones del 28-oct (1a · 2a · 3a):
#   · Se pide desde la ficha del servicio (menú ⚡) o desde el Self-service hub; se elige una
#     release del catálogo, no se escribe una versión a mano.
#   · Port NO aprueba nada: la puerta es la de siempre, el entorno "prod" de GitHub (approved_by en
#     el deployment). Una sola fuente de verdad para la auditoría.
#   · Lanza promote.yml de meridian-orders a través de GitHub Ocean. Las reglas (prod = staging,
#     gitops-ok, Argo CD, linaje) son las mismas que si se lanzara desde GitHub.
#
# Grafo:  trigger (formulario) ──► promote (dispatch_workflow de promote.yml)
locals {
  promote_service = "meridian-orders"
  # Una entrada de entidad puede llegar como identificador o como objeto, según desde dónde se lance
  as_id = "if type == \"object\" then .identifier else . end"
}

resource "port_workflow" "promote" {
  identifier                = "promote-meridian-orders"
  title                     = "Promocionar"
  icon                      = "Deployment"
  category                  = "Entrega"
  description               = "Pide la promoción de una release a staging o prod. Prod exige que esté ya en staging y la aprobación del entorno en GitHub."
  allow_anyone_to_view_runs = true

  # --- 1 · Formulario ---------------------------------------------------------------------------
  node {
    identifier = "trigger"
    title      = "Pedir promoción"

    self_serve_trigger {
      action_card_button_text    = "Promocionar"
      execute_action_button_text = "Solicitar"
      published                  = true

      # Menú ⚡ de la entidad: solo en los servicios que pasan el filtro de la entrada "service".
      # Sin contexto SELF_SERVICE_HUB, también aparece en el Self-service hub.
      contexts {
        on         = "ENTITY"
        user_input = "service"
      }

      permissions {
        roles = ["Admin", "Member"]
      }

      user_inputs {
        order_properties = ["service", "environment", "release"]

        user_properties = {
          string_props = {
            service = {
              title       = "Servicio"
              description = "Solo Meridian Orders tiene hoy este circuito de entrega"
              required    = true
              format      = "entity"
              blueprint   = "service"
              default     = local.promote_service
              dataset = {
                combinator = "and"
                rules = [{
                  property   = "$identifier"
                  operator   = "="
                  value_json = jsonencode(local.promote_service)
                }]
              }
            }
            environment = {
              title       = "Entorno"
              description = "prod: requiere que la versión esté ya en staging y aprobar el entorno en GitHub"
              required    = true
              enum        = ["prod", "staging"]
              default     = "prod"
              enum_colors = { prod = "red", staging = "yellow" }
            }
            release = {
              title       = "Release"
              description = "Versión publicada por release-please (mismas imágenes que se probaron en dev)"
              required    = true
              format      = "entity"
              blueprint   = port_blueprint.release.identifier
              depends_on  = ["service"]
              # Solo las releases del servicio elegido (su identificador empieza por el del servicio)
              dataset = {
                combinator = "and"
                rules = [{
                  property = "$identifier"
                  operator = "contains"
                  value    = { jq_query = ".form.service | ${local.as_id}" }
                }]
              }
              sort = {
                property = "published_at"
                order    = "DESC"
              }
            }
          }
        }
      }
    }
  }

  # --- 2 · Lanzar promote.yml en GitHub ------------------------------------------------------------
  node {
    identifier = "promote"
    title      = "Lanzar promote.yml"
    links      = ["https://github.com/elpalmeral-org/${local.promote_service}/actions/workflows/promote.yml"]

    integration_action {
      installation_id             = "github-ocean"
      integration_provider        = "github-ocean"
      integration_invocation_type = "dispatch_workflow"
      execution_properties = jsonencode({
        org      = "elpalmeral-org"
        repo     = local.promote_service
        workflow = "promote.yml"
        # Port sigue la ejecución y marca el nodo como correcto o fallido cuando termina
        reportWorkflowStatus = true
        workflowInputs = {
          environment = "{{ .outputs.trigger.environment }}"
          # meridian-orders-v0.1.0 → 0.1.0
          version = "{{ .outputs.trigger.release | ${local.as_id} | ltrimstr(\"${local.promote_service}-v\") }}"
        }
      })
    }
  }

  connections {
    source_identifier = "trigger"
    target_identifier = "promote"
  }
}
