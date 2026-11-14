# "Crear servicio" como Workflow de Port (F7, ADR 0035). Golden path de autoservicio: pide un
# nombre y, hoy con una sola opción cada uno, frontend/backend/runtime, y dispara
# crear-servicio.yml en agentic-platform-lab por GitHub Ocean — la misma pieza que lanzarlo a
# mano con `gh workflow run crear-servicio.yml` (igual patrón que pedir-feature/promote).
#
# Crecer el catálogo de frontend/backend/runtime más adelante es ampliar estos enum, no
# rediseñar el formulario (ADR 0035). El repo de destino (agentic-platform-lab, donde vive el
# workflow) no es un campo del formulario: es siempre el mismo, a diferencia de "servicio" en
# pedir-feature/promote.
#
# Grafo: trigger (formulario) ──► crear_servicio (dispatch_workflow de crear-servicio.yml)

resource "port_workflow" "crear_servicio" {
  identifier                = "crear-servicio"
  title                     = "Crear servicio"
  icon                      = "GithubActions"
  category                  = "Plataforma"
  description               = "Crea un repo nuevo, listo para AIDLC y el harness corporativo, y lo da de alta en platform-gitops para desplegarlo en k3s01 (sin activar ningún entorno todavía: eso es un paso manual aparte, ADR 0035)."
  allow_anyone_to_view_runs = true

  # --- 1 · Formulario ------------------------------------------------------------------------------
  node {
    identifier = "trigger"
    title      = "Crear servicio"

    self_serve_trigger {
      action_card_button_text    = "Crear servicio"
      execute_action_button_text = "Crear"
      published                  = true

      permissions {
        roles = ["Admin", "Member"]
      }

      user_inputs {
        order_properties = ["nombre", "frontend", "backend", "runtime"]

        user_properties = {
          string_props = {
            nombre = {
              title       = "Nombre del servicio"
              description = "p. ej. Facturas. Solo letras (sin tildes), dígitos y espacios: de aquí salen el nombre del repo, el paquete Python y el namespace en k3s01"
              required    = true
            }
            frontend = {
              title       = "Frontend"
              description = "Hoy solo Angular (el mismo que meridian-orders); añadir opciones es ampliar este enum"
              required    = true
              enum        = ["angular"]
              default     = "angular"
            }
            backend = {
              title       = "Backend"
              description = "Hoy solo FastAPI (el mismo que meridian-orders); añadir opciones es ampliar este enum"
              required    = true
              enum        = ["fastapi"]
              default     = "fastapi"
            }
            runtime = {
              title       = "Dónde se ejecuta"
              description = "Hoy solo k3s01; añadir opciones es ampliar este enum"
              required    = true
              enum        = ["k3s01"]
              default     = "k3s01"
            }
          }
        }
      }
    }
  }

  # --- 2 · Lanzar crear-servicio.yml en GitHub --------------------------------------------------
  node {
    identifier = "crear_servicio"
    title      = "Lanzar crear-servicio.yml"
    links      = ["{{ .result.workflowRunUrl }}"]

    integration_action {
      installation_id             = "github-ocean"
      integration_provider        = "github-ocean"
      integration_invocation_type = "dispatch_workflow"
      execution_properties = jsonencode({
        org                  = "elpalmeral-org"
        repo                 = "agentic-platform-lab"
        workflow             = "crear-servicio.yml"
        reportWorkflowStatus = true
        workflowInputs = {
          nombre   = "{{ .outputs.trigger.nombre }}"
          frontend = "{{ .outputs.trigger.frontend }}"
          backend  = "{{ .outputs.trigger.backend }}"
          runtime  = "{{ .outputs.trigger.runtime }}"
        }
      })
    }
  }

  connections {
    source_identifier = "trigger"
    target_identifier = "crear_servicio"
  }
}
