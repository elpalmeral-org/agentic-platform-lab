# aidlc_agent · NUEVO (F5). Catálogo de los roles del harness corporativo que corren en el motor A
# (HarnessRouter/UHP) y en el motor B (subagentes de Claude Code): spec-writer, implementer y los
# tres validadores. Fuente de verdad real: `platform-harness/.apm/agents/*.agent.md` (el mandato) y
# `platform-harness/uhp/roles.yaml` (base + modelo + proveedor del motor A). Esto es una FOTO para
# que el catálogo los enseñe como entidades relacionables, no una sincronización automática: si
# `uhp/roles.yaml` cambia, este fichero se actualiza a mano hasta que `harness-sync` (F4.7) lo haga
# por su cuenta.
locals {
  agents = {
    spec-writer = {
      title    = "spec-writer"
      phase    = "PROPOSE"
      model    = "deepseek/deepseek-v3.2"
      readonly = false
    }
    implementer = {
      title    = "implementer"
      phase    = "IMPLEMENT"
      model    = "deepseek/deepseek-v3.2"
      readonly = false
    }
    spec-validator = {
      title    = "spec-validator"
      phase    = "VALIDATE"
      model    = "deepseek/deepseek-v3.2"
      readonly = true
    }
    security-gate = {
      title    = "security-gate"
      phase    = "VALIDATE"
      model    = "deepseek/deepseek-v3.2"
      readonly = true
    }
    impl-conformance = {
      title    = "impl-conformance"
      phase    = "VALIDATE"
      model    = "deepseek/deepseek-v3.2"
      readonly = true
    }
  }
}

resource "port_blueprint" "aidlc_agent" {
  identifier            = "aidlc_agent"
  title                 = "Agente AIDLC"
  icon                  = "GithubActions"
  description           = "Rol del harness corporativo (mandato en platform-harness/.apm/agents/)"
  force_delete_entities = false

  properties = {
    string_props = {
      phase = {
        title       = "Fase AIDLC"
        description = "PROPOSE (spec-writer), IMPLEMENT (implementer) o VALIDATE (los tres validadores)"
        enum        = ["PROPOSE", "IMPLEMENT", "VALIDATE"]
        enum_colors = { PROPOSE = "blue", IMPLEMENT = "orange", VALIDATE = "green" }
      }
      base = {
        title       = "Base (motor A)"
        description = "Base de HarnessRouter/UHP; de uhp/roles.yaml"
      }
      model = {
        title = "Modelo (motor A)"
      }
      provider = {
        title = "Proveedor (motor A)"
        enum  = ["openrouter", "local"]
      }
      mandate_url = {
        title  = "Mandato"
        format = "url"
      }
    }
    boolean_props = {
      read_only = {
        title       = "Solo lectura"
        description = "No edita ficheros ni ejecuta nada que los cambie (base de seguridad §7)"
      }
    }
  }
}

resource "port_entity" "agent" {
  for_each   = local.agents
  blueprint  = port_blueprint.aidlc_agent.identifier
  identifier = each.key
  title      = each.value.title
  properties = {
    string_props = {
      phase       = each.value.phase
      base        = "opencode"
      model       = each.value.model
      provider    = "openrouter"
      mandate_url = "https://github.com/elpalmeral-org/platform-harness/blob/main/.apm/agents/${each.key}.agent.md"
    }
    boolean_props = { read_only = each.value.readonly }
  }
}
