# F3.4c · Webhook por el que Argo CD confirma los despliegues (ADR 0020).
# Argo CD (notificaciones, saliente) → este webhook → deployment Pending pasa a Success o Failure.
#
# ⚠️ La URL lleva la clave del webhook: quien la tenga puede escribir despliegues. NO se publica
# como output ni va a Git: se lee del estado (S3, privado) y se guarda en 1Password
# (agentic-lab/Port webhook argocd), de donde la toma ESO para Argo CD.
locals {
  # Cuerpo que envía la plantilla "port-deployment" de Argo CD (platform-gitops, argocd-values.yaml):
  # {app, sync, health, phase, revision, finishedAt, images[]}
  argo_env = "(.body.app | ltrimstr(\"meridian-orders-\"))"
  argo_tag = "([.body.images[]? | select(contains(\"/meridian-orders-\"))][0] // \"\" | capture(\":(?<t>[^:@/]+)@sha256\").t)"
  # Una degradación sin operación en curso llega sin finishedAt: se usa la hora de recepción
  argo_time = "(if (.body.finishedAt // \"\") == \"\" then (now | todate) else .body.finishedAt end)"
}

resource "port_webhook" "argocd" {
  identifier  = "argocd-deployments"
  title       = "Argo CD · despliegues" # máx. 30 caracteres
  description = "Argo CD notifica sync+salud de las Applications de Meridian Orders; cierra el deployment que abrió platform-gitops"
  icon        = "Argo"
  enabled     = true

  mappings = [
    {
      blueprint = port_blueprint.deployment.identifier
      filter    = ".body.app | startswith(\"meridian-orders-\")"
      entity = {
        identifier = "\"meridian-orders-\" + ${local.argo_env} + \"-\" + ${local.argo_tag}"
        properties = {
          deploymentStatus = "if .body.health == \"Healthy\" and .body.phase == \"Succeeded\" then \"Success\" elif .body.health == \"Degraded\" or .body.phase == \"Failed\" or .body.phase == \"Error\" then \"Failure\" else \"Pending\" end"
          confirmed_at     = local.argo_time
          createdAt        = local.argo_time
          gitops_revision  = ".body.revision"
          tag              = local.argo_tag
          environment      = "{\"dev\": \"Development\", \"staging\": \"Staging\", \"prod\": \"Production\"}[${local.argo_env}]"
        }
        relations = {
          service            = "\"meridian-orders\""
          target_environment = local.argo_env
        }
      }
    }
  ]
}
