# F3.6 · Acción self-service "Promocionar" (decidido el 28-oct: 1a · 2a · 3a).
#   · Se PIDE desde la ficha del servicio; se elige una release del catálogo (no texto libre).
#   · Port NO aprueba nada: la puerta es la de siempre, el entorno "prod" de GitHub (approved_by
#     en el deployment). Una sola fuente de verdad para la auditoría.
#   · Lanza promote.yml de meridian-orders a través de GitHub Ocean (INTEGRATION_ACTION). Las reglas
#     (prod = staging, gitops-ok, Argo CD, linaje) son las mismas que si se lanzara desde GitHub.
resource "port_action" "promote" {
  identifier  = "promote_meridian_orders"
  title       = "Promocionar"
  icon        = "Deployment"
  description = "Pide la promoción de una release a staging o prod. Prod exige que esté ya en staging y la aprobación del entorno en GitHub."

  self_service_trigger = {
    operation                  = "DAY-2"
    blueprint_identifier       = "service"
    action_card_button_text    = "Promocionar"
    execute_action_button_text = "Pedir promoción"
    # Solo Meridian Orders tiene hoy este circuito de entrega
    condition = jsonencode({
      type       = "SEARCH"
      combinator = "and"
      rules      = [{ property = "$identifier", operator = "=", value = "meridian-orders" }]
    })

    user_properties = {
      string_props = {
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
          # Solo las releases de este servicio (su identificador empieza por el del servicio)
          dataset = {
            combinator = "and"
            rules = [{
              property = "$identifier"
              operator = "contains"
              value    = { jq_query = ".entity.identifier" }
            }]
          }
          sort = {
            property = "published_at"
            order    = "DESC"
          }
        }
      }
    }
    order_properties = ["environment", "release"]
  }

  integration_method = {
    installation_id         = "github-ocean"
    integration_action_type = "dispatch_workflow"
    integration_action_execution_properties = {
      org                    = "elpalmeral-org"
      repo                   = "meridian-orders"
      workflow               = "promote.yml"
      report_workflow_status = "true"
      workflow_inputs = jsonencode({
        environment = "{{ .inputs.environment }}"
        # meridian-orders-v0.1.0 → 0.1.0 (vale tanto si llega el objeto entidad como su identificador)
        version = "{{ .inputs.release | if type == \"object\" then .identifier else . end | ltrimstr(\"meridian-orders-v\") }}"
      })
    }
  }

  required_approval = false
  publish           = true
}
