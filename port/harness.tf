# harness_status · NUEVO (F4.8). Qué versión del harness corporativo tiene fijada un servicio
# AHORA MISMO, y si pasa las puertas que ya evalúa harness-ok en cada PR (apm audit, firma de la
# release fijada, versión mínima de pr_gates.rego). Una entidad por servicio, actualizada en su
# sitio (no histórica, a diferencia de build/release): la escribe harness-ok.yml al fusionar en
# main (push, no solo PR), con el mismo golden path que build/release (ADR 0020,
# platform-gitops/.github/actions/port-entity).
resource "port_blueprint" "harness_status" {
  identifier            = "harness_status"
  title                 = "Estado del harness"
  icon                  = "GithubActions"
  description           = "Versión del harness corporativo fijada por un servicio y si pasa las puertas de harness-ok"
  force_delete_entities = false

  properties = {
    string_props = {
      version = {
        title       = "Versión fijada"
        description = "De apm.lock.yaml, no del tag del pin (que es un SHA)"
      }
      checked_at = {
        title  = "Última comprobación"
        format = "date-time"
      }
    }
    boolean_props = {
      audit_ok = {
        title       = "Sin drift"
        description = "apm audit --ci"
      }
      signature_ok = {
        title       = "Release firmada verificada"
        description = "cosign verify-blob contra la release fijada en apm.lock.yaml"
      }
      min_version_ok = {
        title       = "Versión mínima cumplida"
        description = "minimum_harness_version de policy/opa/pr_gates.rego"
      }
    }
  }

  relations = {
    service = {
      title  = "Servicio"
      target = "service"
    }
  }
}
