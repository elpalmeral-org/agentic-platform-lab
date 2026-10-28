# port/ · el modelo de Port como código

[ADR 0017](../docs/adr/0017-port-como-codigo-terraform.md) (Terraform, `plan` en PR y `apply` en `main`) ·
[ADR 0018](../docs/adr/0018-adoptar-plantillas-port.md) (adoptar las plantillas de Port que cuentan la historia) ·
diseño en [`docs/lab/port.md`](../docs/lab/port.md).

## Qué gestiona Terraform y qué no

| Gestiona | No gestiona (vive en la UI o lo alimentan las integraciones) |
|---|---|
| `environment` (y sus entidades `dev`, `staging`, `prod`), `deployment`, `workload`, `build`, `release`, *mapping* de GitHub Ocean, webhook de Argo CD, scorecards del acto 1, la ficha del servicio (`pages/`) y los Workflows *self-service* (`workflow-*.tf`, [ADR 0021](../docs/adr/0021-workflows-port-en-lugar-de-acciones.md)) | `service`, `github*`, `k8s_*`, `argocd*`, `dynatrace*`, `awsAccount`, `cloudResource`, `organization`, las scorecards de plantilla, los blueprints de sistema `_*` |

Las **entidades** que crean los pipelines y las integraciones no las toca Terraform.

## Trabajar en local

```bash
cd port
set -a; source ../lab.env; set +a
export PORT_CLIENT_ID="$(op read -n 'op://agentic-lab/Port Org/ClientId')"
export PORT_CLIENT_SECRET="$(op read -n 'op://agentic-lab/Port Org/ClientSecret')"
export PORT_BETA_FEATURES_ENABLED=true   # port_page es beta
terraform init -backend-config="bucket=$TF_STATE_BUCKET" -backend-config="region=$AWS_REGION"
terraform plan
```

En CI lo mismo lo hace el workflow `port` (F3.1b), con OIDC hacia AWS y el entorno `port` de GitHub.
