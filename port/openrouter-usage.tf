# openrouter_usage · NUEVO (F6.2, ADR 0032). Consumo de la clave de OpenRouter
# (harnessrouter-k3s01, 10 $ sin recarga), leído de GET /v1/key (solo lectura, no gasta
# presupuesto) y publicado por un workflow programado (.github/workflows/openrouter-usage.yml).
# Entidad única (la clave es de la plataforma, no de un servicio): no lleva relación a "service".
resource "port_blueprint" "openrouter_usage" {
  identifier            = "openrouter_usage"
  title                 = "Consumo de OpenRouter"
  icon                  = "DevopsTool"
  description           = "Consumo real de la clave de OpenRouter de la plataforma (10 $, sin recarga), leído de GET /v1/key"
  force_delete_entities = false

  properties = {
    string_props = {
      checked_at = {
        title  = "Última comprobación"
        format = "date-time"
      }
    }
    number_props = {
      limit = {
        title       = "Límite"
        description = "Tope de la clave en dólares"
      }
      usage = {
        title       = "Consumido"
        description = "Gasto acumulado en dólares desde que se creó la clave"
      }
      limit_remaining = {
        title       = "Remanente"
        description = "limit - usage, tal cual lo devuelve OpenRouter"
      }
    }
  }
}
