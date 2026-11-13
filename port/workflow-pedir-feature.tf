# "Pedir feature" como Workflow de Port (F5, ADR 0021, ADR 0025). Selector de servicio + motor:
#   servicio → cualquier entidad del blueprint "service" (hoy solo meridian-orders; sin filtro de
#              dataset, para que entre sola cada servicio nuevo que se añada al catálogo)
#   abierto  → dispatch_workflow de aidlc-propose.yml (runner ARC → HarnessRouter, ADR 0031)
#   Claude   → create_issue con la etiqueta aidlc:claude (Pablo corre /feature #issue en su Mac)
#
# Grafo: trigger (formulario) ──► check_motor (condition) ──┬─► propose (motor abierto)
#                                                            └─► crear_issue (motor Claude, fallback)
#
# El motor A hoy solo prueba la cadena mecánica (Port → GitHub → runner ARC → HarnessRouter): sin
# clave de API de la Console (F4.7, pendiente de confirmar), aidlc-propose.yml falla con un mensaje
# claro. No se simula un resultado que no es real.
#
# Cada servicio nuevo necesita sus propios aidlc-propose.yml/aidlc-implement.yml y la etiqueta
# aidlc:claude (como meridian-orders); el workflow no lo comprueba por sí solo.
locals {
  pedir_feature_default_service = "meridian-orders"
}

resource "port_workflow" "pedir_feature" {
  identifier                = "pedir-feature"
  title                     = "Pedir feature"
  icon                      = "GithubActions"
  category                  = "AIDLC"
  description               = "Propone una feature en lenguaje natural para el servicio elegido. Motor abierto: la propone un agente vía HarnessRouter. Claude: abre un issue para correr /feature en el Mac."
  allow_anyone_to_view_runs = true

  # --- 1 · Formulario ----------------------------------------------------------------------------
  node {
    identifier = "trigger"
    title      = "Pedir feature"

    self_serve_trigger {
      action_card_button_text    = "Pedir feature"
      execute_action_button_text = "Pedir"
      published                  = true

      permissions {
        roles = ["Admin", "Member"]
      }

      user_inputs {
        order_properties = ["servicio", "motor", "cambio", "peticion"]

        user_properties = {
          string_props = {
            servicio = {
              title       = "Servicio"
              description = "El repo de meridian-orders u otro servicio del catálogo que ya tenga aidlc-propose.yml/aidlc-implement.yml y la etiqueta aidlc:claude"
              required    = true
              format      = "entity"
              blueprint   = "service"
              default     = local.pedir_feature_default_service
            }
            motor = {
              title       = "Motor"
              description = "Abierto: lo propone un agente vía HarnessRouter (OpenRouter/Bonsai). Claude: abre un issue para que una persona corra /feature en su Mac con la suscripción"
              required    = true
              enum        = ["abierto", "claude"]
              enum_colors = { abierto = "blue", claude = "purple" }
            }
            cambio = {
              title       = "Nombre del cambio"
              description = "kebab-case, p. ej. filtrar-pedidos-por-telefono"
              required    = true
            }
            peticion = {
              title       = "Petición"
              description = "En lenguaje natural: qué se pide y por qué"
              required    = true
              format      = "multi-line"
            }
          }
        }
      }
    }
  }

  # --- 2 · ¿Qué motor? ----------------------------------------------------------------------------
  node {
    identifier = "check_motor"
    title      = "¿Qué motor?"

    condition {
      outlets {
        identifier = "abierto"
        title      = "Motor abierto"
        expression = ".outputs.trigger.motor == \"abierto\""
      }
    }
  }

  # --- 3a · Motor abierto: dispatch_workflow de aidlc-propose.yml --------------------------------
  node {
    identifier = "propose"
    title      = "Lanzar aidlc-propose.yml"
    links      = ["{{ .result.workflowRunUrl }}"]

    integration_action {
      installation_id             = "github-ocean"
      integration_provider        = "github-ocean"
      integration_invocation_type = "dispatch_workflow"
      execution_properties = jsonencode({
        org                  = "elpalmeral-org"
        repo                 = "{{ .outputs.trigger.servicio | ${local.as_id} }}"
        workflow             = "aidlc-propose.yml"
        reportWorkflowStatus = true
        workflowInputs = {
          cambio   = "{{ .outputs.trigger.cambio }}"
          peticion = "{{ .outputs.trigger.peticion }}"
        }
      })
    }
  }

  # --- 3b · Motor Claude: issue con la etiqueta aidlc:claude --------------------------------------
  node {
    identifier = "crear_issue"
    title      = "Crear issue aidlc:claude"
    links      = ["{{ .result.issueUrl }}"]

    integration_action {
      installation_id             = "github-ocean"
      integration_provider        = "github-ocean"
      integration_invocation_type = "create_issue"
      execution_properties = jsonencode({
        org    = "elpalmeral-org"
        repo   = "{{ .outputs.trigger.servicio | ${local.as_id} }}"
        title  = "{{ .outputs.trigger.cambio }}"
        body   = "{{ .outputs.trigger.peticion }}\n\n---\nMotor: Claude. Corre `/feature {{ .outputs.trigger.cambio }} \"{{ .outputs.trigger.peticion }}\"` en el Mac (motor B, ADR 0025)."
        labels = ["aidlc:claude"]
      })
    }
  }

  connections {
    source_identifier = "trigger"
    target_identifier = "check_motor"
  }
  connections {
    source_identifier        = "check_motor"
    source_outlet_identifier = "abierto"
    target_identifier        = "propose"
  }
  connections {
    source_identifier = "check_motor"
    target_identifier = "crear_issue"
    fallback          = true
  }
}
