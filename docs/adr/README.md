# Decisiones de arquitectura (ADR)

Formato: contexto → decisión → consecuencias. Una ADR aceptada no se edita; si cambia la
decisión, se escribe otra que la sustituye.

| ADR | Título | Estado | Fecha |
|---|---|---|---|
| [0001](0001-repo-nuevo-y-tres-capas.md) | Repo nuevo y separación setup · lab · demo | Aceptada | 2026-10-23 |
| [0002](0002-repos-publicos-org-free.md) | Repos públicos en una org GitHub Free | Aceptada | 2026-10-23 |
| [0003](0003-k3s-un-nodo-recortando-docker01.md) | k3s de un nodo en VM nueva, recortando docker01 | Aceptada | 2026-10-23 |
| [0004](0004-monorepo-app-y-gitops-aparte.md) | Monorepo de aplicación y repo GitOps aparte | Aceptada | 2026-10-23 |
| [0005](0005-port-como-idp.md) | Port.io (Free) como IDP | Aceptada | 2026-10-23 |
| [0006](0006-uhp-harnessrouter-gateway.md) | UHP con HarnessRouter CE como gateway de agentes | Aceptada | 2026-10-23 |
| [0007](0007-argocd-gitops.md) | Argo CD como motor GitOps | Aceptada | 2026-10-24 |
| [0008](0008-secretos-eso-1password.md) | Secretos con External Secrets Operator y 1Password | Aceptada | 2026-10-24 |
| [0009](0009-tls-letsencrypt-dns01-route53.md) | TLS con Let's Encrypt por DNS-01 en Route 53 | Aceptada | 2026-10-24 |
| [0010](0010-nombres-publicos-gitops-y-doh.md) | Nombres del lab en `platform-gitops` y comprobación DNS-01 por DoH | Aceptada | 2026-10-24 |
| [0011](0011-trunk-based-release-please.md) | Trunk-based y release-please en `meridian-orders` | Aceptada | 2026-10-25 |
| [0012](0012-promocion-por-pr-gitops.md) | Promoción entre entornos por PR en `platform-gitops` | Aceptada | 2026-10-25 |
| [0013](0013-postgresql-cloudnativepg.md) | PostgreSQL con CloudNativePG | Aceptada | 2026-10-25 |
| [0014](0014-github-app-platform-bot.md) | Una GitHub App como identidad de la plataforma | Aceptada | 2026-10-25 |
| [0015](0015-puerta-gitops-ok.md) | La plataforma hace cumplir las reglas de promoción con `gitops-ok` | Aceptada | 2026-10-27 |
| [0016](0016-linaje-mixto-port.md) | Linaje en Port: inventario por integraciones, eventos por los pipelines | Aceptada | 2026-10-27 |
| [0017](0017-port-como-codigo-terraform.md) | El modelo de Port como código con Terraform, aplicado por PR | Aceptada | 2026-10-27 |
| [0018](0018-adoptar-plantillas-port.md) | Adoptar las plantillas de Port que cuentan la historia; el resto, como escaparate | Aceptada | 2026-10-27 |
| [0019](0019-exportador-kubernetes-gitops.md) | El exportador de Kubernetes de Port como addon GitOps, con su mapping en `platform-gitops` | Aceptada | 2026-10-27 |
| [0020](0020-linaje-accion-plataforma-y-argo.md) | Linaje con una acción de plataforma; el despliegue lo confirma Argo CD | Aceptada | 2026-10-27 |
| [0021](0021-workflows-port-en-lugar-de-acciones.md) | Lo que se pide desde Port se construye como Workflow, no como acción clásica | Aceptada | 2026-10-28 |
| [0022](0022-harness-repo-propio-formatos-abiertos.md) | El harness corporativo vive en su propio repo y se escribe en formatos abiertos | Aceptada | 2026-10-28 |
| [0023](0023-apm-distribucion-harness-ok.md) | APM distribuye el harness a los repos; `harness-ok` lo hace cumplir | Aceptada | 2026-10-28 |
| [0024](0024-harnessrouter-en-f4-proveedores.md) | HarnessRouter llega en F4 y aloja el harness por rol y versión; tres proveedores | Aceptada | 2026-10-28 |
