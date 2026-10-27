# ADR 0018 · Adoptar las plantillas de Port que cuentan la historia; el resto, como escaparate

- **Estado:** Aceptada · 2026-10-27 · matiza la [ADR 0017](0017-port-como-codigo-terraform.md)

## Contexto

Al crear la org, Port montó un portal de inicio con unos 25 blueprints (`service`, `environment`,
`deployment`, `workload`, `github*`, `k8s_*`, `argocd*`, `dynatrace*`, `awsAccount`…) y 15
scorecards, incluidas DORA, *production readiness* y fiabilidad. Varios coinciden en nombre e
intención con el modelo de [lab/port](../lab/port.md). Además, **sirven para enseñar capacidades
de Port** aunque estén vacíos.

Opciones: borrarlo todo y crear nuestro modelo desde cero, o adoptar lo que encaja.

## Decisión

**Adoptar y ampliar.**

| Grupo | Blueprints | Quién lo gestiona |
|---|---|---|
| **Cuenta el hilo y lo ampliamos** | `environment` (y sus entidades `dev`/`staging`/`prod`), `deployment` (un **evento** por promoción), `workload` (lo aprobado frente a lo que corre) | **Terraform**: se importan tal como están y se amplían |
| **Nuevos** | `build`, `release` | **Terraform** |
| **Lo alimentan las integraciones** | `github*` (GitHub Ocean), `k8s_*` y `argocd*` (exportador de Kubernetes) | la UI de Port; el *mapping* de la integración, en Terraform |
| **Escaparate** | `service` (de momento), `organization`, `dynatrace*`, `awsAccount`, `cloudResource`, las 15 scorecards de plantilla | la UI de Port |

Regla: **lo que cuenta la historia de la demo es código; lo que solo enseña capacidades vive en
la UI**. Si algo del escaparate pasa a contar la historia, se importa.

## Consecuencias

- ✅ DORA sale gratis: `service` ya agrega la frecuencia de despliegue y el *lead time* a partir de
  `deployment` con `environment = "Production"` y `deploymentStatus = "Success"`. Basta con que
  `platform-gitops` envíe esos eventos.
- ✅ En la demo hay contenido de Port que enseñar (Kubernetes, Argo CD, scorecards) sin construirlo.
- ⚠️ Un blueprint importado se gestiona **entero**: su código parte del generado por
  `terraform plan -generate-config-out` y se revisa antes de ampliarlo.
- ⚠️ El portal mezcla blueprints gestionados y no gestionados: el [README de `port/`](../../port/README.md)
  dice cuál es cuál.
- ⚠️ `deployment` deja de ser "lo actual por entorno" (diseño del 27-oct) y pasa a ser el evento;
  "lo actual" es `workload`.
