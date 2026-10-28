# F3.5 · Scorecards del acto 1 (CISO y arquitectura). Niveles por defecto de Port:
# Basic → Bronze → Silver → Gold; cada nivel exige también las reglas de los anteriores.
# Las 15 scorecards de la plantilla (DORA, fiabilidad, production readiness) siguen en la UI (ADR 0018).
locals {
  # Condición de scorecard: Port la espera como JSON en una cadena
  is_true   = { operator = "=", value = true }
  not_empty = { operator = "isNotEmpty" }
}

# --- ¿Sabemos qué hay dentro de lo que corre y quién lo construyó? (por componente y entorno) ---
resource "port_scorecard" "supply_chain" {
  blueprint  = port_blueprint.workload.identifier
  identifier = "supply_chain"
  title      = "Cadena de suministro"

  rules = [
    {
      identifier  = "signed"
      title       = "Imagen firmada por nuestro pipeline"
      description = "cosign keyless de publish.yml en main, verificado por la plataforma"
      level       = "Bronze"
      query = {
        combinator = "and"
        conditions = [jsonencode(merge(local.is_true, { property = "signed" }))]
      }
    },
    {
      identifier  = "sbom_provenance"
      title       = "SBOM y procedencia SLSA adjuntos"
      description = "Se sabe qué contiene la imagen y cómo se construyó"
      level       = "Silver"
      query = {
        combinator = "and"
        conditions = [
          jsonencode(merge(local.is_true, { property = "sbom" })),
          jsonencode(merge(local.is_true, { property = "provenance" })),
        ]
      }
    },
    {
      identifier  = "no_critical_cves"
      title       = "0 CVE críticas con corrección disponible"
      description = "Según Grype al publicar (la imagen no se publica si las hay)"
      level       = "Gold"
      query = {
        combinator = "and"
        conditions = [jsonencode({ property = "critical_cves", operator = "=", value = 0 })]
      }
    },
  ]
}

# --- ¿Lo que corre es exactamente lo aprobado? (por componente y entorno) ---
resource "port_scorecard" "governed_runtime" {
  blueprint  = port_blueprint.workload.identifier
  identifier = "governed_runtime"
  title      = "Corre lo aprobado"

  rules = [
    {
      identifier  = "pinned_by_digest"
      title       = "Fijado por digest en GitOps"
      description = "platform-gitops declara un digest inmutable, no un tag"
      level       = "Bronze"
      query = {
        combinator = "and"
        conditions = [jsonencode(merge(local.not_empty, { property = "approved_digest" }))]
      }
    },
    {
      identifier  = "argo_synced_healthy"
      title       = "Argo CD: sincronizado y sano"
      description = "El clúster coincide con Git y la aplicación responde"
      level       = "Silver"
      query = {
        combinator = "and"
        conditions = [
          jsonencode({ property = "argo_sync_status", operator = "=", value = "Synced" }),
          jsonencode({ property = "argo_health_status", operator = "=", value = "Healthy" }),
        ]
      }
    },
    {
      identifier  = "in_sync"
      title       = "La imagen en ejecución es la aprobada"
      description = "Dos fuentes independientes coinciden: el overlay de GitOps y el clúster"
      level       = "Gold"
      query = {
        combinator = "and"
        conditions = [jsonencode(merge(local.is_true, { property = "in_sync" }))]
      }
    },
  ]
}

# --- ¿La promoción pasó por las puertas? (por despliegue) ---
resource "port_scorecard" "promotion_gates" {
  blueprint  = port_blueprint.deployment.identifier
  identifier = "promotion_gates"
  title      = "Promoción con puertas"

  rules = [
    {
      identifier  = "via_pr"
      title       = "Llegó por PR (gitops-ok en verde)"
      description = "Nadie aplica cambios a mano: la plataforma valida digest, firma y prod = staging"
      level       = "Bronze"
      query = {
        combinator = "and"
        conditions = [jsonencode(merge(local.not_empty, { property = "promotion_pr_url" }))]
      }
    },
    {
      identifier  = "confirmed_by_argo"
      title       = "Confirmado por Argo CD"
      description = "El entorno quedó sincronizado y sano tras el merge"
      level       = "Silver"
      query = {
        combinator = "and"
        conditions = [jsonencode({ property = "deploymentStatus", operator = "=", value = "Success" })]
      }
    },
    {
      identifier  = "human_gate"
      title       = "Una persona lo decidió"
      description = "Aprobación del entorno (prod) o PR fusionado por una persona (staging). En dev no hay puerta humana por diseño"
      level       = "Gold"
      query = {
        combinator = "or"
        conditions = [
          jsonencode(merge(local.not_empty, { property = "approved_by" })),
          jsonencode({ property = "merged_by", operator = "!=", value = "elpalmeral-platform-bot[bot]" }),
        ]
      }
    },
  ]
}
