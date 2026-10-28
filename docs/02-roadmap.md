# 02 · Roadmap

> Se avanza **paso a paso**: un paso no empieza hasta que el anterior está confirmado.
> Leyenda: ✅ hecho · 🟡 en curso · ⚪ pendiente · ❓ requiere decisión

## 1. Fases

```mermaid
flowchart LR
    F0["F0 · Setup<br/>capacidad · VM · k3s · cuentas"]
    F1["F1 · Plataforma base<br/>GitOps · secretos · ingress/TLS"]
    F2["F2 · App de ejemplo<br/>meridian-orders · CI · promoción"]
    F3["F3 · IDP<br/>Port: catálogo · acciones · scorecards"]
    F4["F4 · Harness Engineering<br/>harness versionado · OpenSpec · OPA"]
    F5["F5 · Agent Platform<br/>UHP · ARC · AIDLC · gates agénticos"]
    F6["F6 · Observabilidad<br/>trazas · coste por agente"]
    F7["F7 · Demo kit<br/>guion · escenarios · reset"]

    F0 --> F1 --> F2 --> F3
    F2 --> F4 --> F5
    F3 --> F5
    F5 --> F6 --> F7
```

| Fase | Capa | Objetivo | Estado |
|---|---|---|---|
| F0 | Setup | Tener k3s01 funcionando y las cuentas listas | 🟡 |
| F1 | Lab | El clúster se gestiona solo desde `platform-gitops` | ✅ (salvo Kyverno y cuotas ⏸️) |
| F2 | Lab | Meridian Orders (FastAPI + Angular) se construye, firma y promociona por GitOps | ✅ 27-oct |
| F3 | Lab | Port refleja repos, despliegues y entornos; acciones *self-service* operativas | ⚪ |
| F4 | Lab | El harness corporativo es un artefacto versionado que el repo de la app consume | ⚪ |
| F5 | Lab | Un agente lleva una feature de la petición al PR, a través de UHP, con puertas humanas | ⚪ |
| F6 | Lab | Cada ejecución de agente es trazable y tiene coste visible en Grafana y en Port | ⚪ |
| F7 | Demo | Guion de 30-45 min reproducible y *reset* en menos de 10 min | ⚪ |

## 2. Fase 0 · Setup (detalle)

```mermaid
flowchart TD
    P00["Paso 00<br/>Liberar capacidad<br/>(recortar docker01)"] --> P01["Paso 01<br/>VM k3s01<br/>(Terraform)"]
    P01 --> P02["Paso 02<br/>Instalar k3s<br/>+ kubeconfig en el Mac"]
    P03["Paso 03<br/>Cuentas: org GitHub + Port<br/>(en paralelo)"]
    P02 --> F1(["Fase 1"])
    P03 --> F1
```

| Paso | Qué | Doc | Estado |
|---|---|---|---|
| 00 | Medir y recortar docker01 a 24 GiB | [paso-00-capacidad](setup/paso-00-capacidad.md) | ✅ 24 GiB + hugepages 1 GiB + NUMA · ⚠️ falta revisar la reserva de hugepages del host |
| 01a | Plantilla Debian 13 cloud-init (9013) con usuario `pfj` y clave de 1Password | `homelab-terraform/templates/debian13` | ✅ |
| 01 | Crear la VM `k3s01` con Terraform y su DNS | [paso-01-vm-k3s01](setup/paso-01-vm-k3s01.md) | ✅ |
| 02 | Instalar k3s, kubeconfig en el Mac, prueba de humo | [paso-02-k3s](setup/paso-02-k3s.md) | 🟡 k3s `v1.36.5+k3s1` instalado, pods y almacenamiento OK · falta `curl` al ingress y snapshot |
| 03 | Configurar la org GitHub, publicar este repo, crear la org en Port | [paso-03-cuentas](setup/paso-03-cuentas.md) | 🟡 repo publicado y Port listo · falta confirmar ajustes de la org (3.1) y ruleset (3.3) |

## 3. Fases siguientes (borrador, se detallarán al llegar)

### F1 · Plataforma base (decidida el 24-oct)

Argo CD ([ADR 0007](adr/0007-argocd-gitops.md)) · ESO + 1Password ([ADR 0008](adr/0008-secretos-eso-1password.md)) ·
Let's Encrypt DNS-01 en Route 53 ([ADR 0009](adr/0009-tls-letsencrypt-dns01-route53.md)).

```mermaid
flowchart LR
    subgraph SETUP["① Setup (manual)"]
        P04["Paso 04<br/>bóveda agentic-lab<br/>service account · IAM Route 53"]
        P05["Paso 05<br/>repo platform-gitops<br/>bootstrap Argo CD + token ESO"]
    end
    subgraph LAB["② Lab (GitOps, por oleadas)"]
        W0["ola 0<br/>Argo CD se autogestiona<br/>External Secrets"]
        W1["ola 1<br/>ClusterSecretStore 1Password<br/>cert-manager"]
        W2["ola 2<br/>ExternalSecret Route 53<br/>ClusterIssuer LE staging → prod"]
        W3["ola 3<br/>Certificate *.apl<br/>TLS por defecto en Traefik"]
        W4["ola 4<br/>Ingress HTTPS de Argo CD<br/>Kyverno + cuotas"]
    end
    P04 --> P05 --> W0 --> W1 --> W2 --> W3 --> W4
```

| Paso | Capa | Qué | Estado |
|---|---|---|---|
| 04 | Setup | Bóveda `agentic-lab`, service account de 1Password, usuario IAM para DNS-01 | ✅ ([doc](setup/paso-04-secretos-externos.md)) · limpiar tokens viejos de `agentic-lab` |
| 05 | Setup | Repo `platform-gitops`, bootstrap de Argo CD y del token de ESO | ✅ ([doc](setup/paso-05-bootstrap-gitops.md)) |
| — | Lab | Olas -1 a 1: Argo CD autogestionado, External Secrets, `ClusterSecretStore` | ✅ ([argocd](lab/argocd.md) · [secretos](lab/secretos.md)) |
| PR 1 | Lab | Olas 2-3: cert-manager, `ClusterIssuer` LE, comodín `*.apl` en staging, TLS por defecto en Traefik | ✅ #1 ([doc](lab/ingress-tls.md)) |
| PR 2 | Lab | Emisor a prod + Argo CD en `https://argocd.apl.<dominio>` | ✅ #2 |
| — | Lab | Ola 4: Kyverno y cuotas por namespace | ⏸️ **pendiente** (aplazado el 25-oct; se retoma tras F2) |

### F2 · Aplicación de ejemplo (decidida el 25-oct)

Trunk-based + release-please ([ADR 0011](adr/0011-trunk-based-release-please.md)) · promoción por PR en
`platform-gitops` ([ADR 0012](adr/0012-promocion-por-pr-gitops.md)) · PostgreSQL con CloudNativePG
([ADR 0013](adr/0013-postgresql-cloudnativepg.md)) · GitHub App `elpalmeral-platform-bot`
([ADR 0014](adr/0014-github-app-platform-bot.md)). Diseño completo: [lab/meridian-orders](lab/meridian-orders.md).

| Paso | Capa | Qué | Estado |
|---|---|---|---|
| 06 | Setup | GitHub App, repo `meridian-orders` vacío, variable y secreto de org | ✅ ([doc](setup/paso-06-github-app.md)) |
| F2.1 | Lab | Código: FastAPI + Angular 22, OpenSpec de `orders`, Dockerfiles, tests | ✅ PR #1 |
| F2.2 | Lab | CI de PR por rutas, títulos Conventional Commits, release-please | ✅ PR #2 |
| F2.3 | Lab | Publicación: GHCR, SBOM, procedencia, Grype, cosign (reordenado: va antes del despliegue) | ✅ |
| F2.4a | Lab | Despliegue en dev: CloudNativePG + base + overlay dev + ApplicationSet | ✅ `platform-gitops` #3 |
| F2.4b | Lab | CD: PR automáticos de promoción (dev, staging), prod con aprobación y puerta `gitops-ok` ([ADR 0015](adr/0015-puerta-gitops-ok.md), [doc](lab/ci-cd.md)) | ✅ `0.1.0` en los tres entornos |

> La puntuación de riesgo de pedidos **no** entra en F2: se reserva como primera feature AIDLC (F5).

### F3 · IDP con Port (decidida el 27-oct)

Linaje mixto: inventario por integraciones y eventos por los pipelines ([ADR 0016](adr/0016-linaje-mixto-port.md)) ·
modelo como código con Terraform, `plan` en PR y `apply` en `main`, estado en S3 por OIDC
([ADR 0017](adr/0017-port-como-codigo-terraform.md)). Diseño completo: [lab/port](lab/port.md).
Objetivo: el **acto 1** de la [demo](demo/README.md), con un solo servicio real.

| Paso | Capa | Qué | Estado |
|---|---|---|---|
| 07 | Setup | Bucket S3 del estado, rol OIDC, entorno `port` en GitHub, GitHub Ocean sin recursos por defecto | ✅ ([doc](setup/paso-07-port.md)) |
| F3.1 | Lab | Adoptar plantillas ([ADR 0018](adr/0018-adoptar-plantillas-port.md)): importar `environment`/`deployment`/`workload`, crear `build`/`release` · workflow `plan`/`apply` | ✅ PR #1 |
| F3.2 | Lab | *Mapping* de GitHub Ocean como código (repos, `service`, PR, releases, workflows) | ✅ PR #2 |
| F3.3 | Lab | `port-k8s-exporter` como addon de `platform-gitops` → lo que corre ([ADR 0019](adr/0019-exportador-kubernetes-gitops.md)) | ✅ |
| F3.4 | Lab | Linaje con acción de plataforma; despliegue confirmado por Argo CD ([ADR 0020](adr/0020-linaje-accion-plataforma-y-argo.md)): a) aprobado · b) `publish.yml` · c) Argo → webhook | ✅ |
| F3.5 | Lab | Scorecards (cadena de suministro, despliegue gobernado) y ficha del acto 1 | ⚪ |
| F3.6 | Lab | Acción *self-service* "Promocionar a prod" | ⚪ |

**Backlog:** ADR y reglas de plataforma como entidades del catálogo (decidido el 27-oct: más adelante).

### F4 · Harness Engineering
- Harness corporativo: `AGENTS.md`/`CLAUDE.md`, skills, hooks deterministas, agentes validadores, corpus de grounding, políticas OPA.
- Versionado y firma; `harness.lock` en la app y *drift gate*.
- OpenSpec como contrato de SDD.

### F5 · Enterprise Agent Platform
- HarnessRouter CE en k3s (manifiestos propios: no hay chart oficial).
- ARC (*Actions Runner Controller*) con runners efímeros.
- Workflows `aidlc-propose` y `aidlc-implement`; 3 validadores agénticos en cada PR.
- Agentes como entidades del catálogo de Port.

### F6 · Observabilidad
- OTel desde HarnessRouter, runners y app hacia el obs-stack de docker01.
- Coste y tokens por dominio, agente y versión de harness; reflejo en Port.

### F7 · Demo kit
- Guion, prompts, escenarios (feature feliz, spec rechazada, gate que bloquea, rollback).
- *Reset*: snapshot de k3s01 + Argo CD + limpieza de PR/ramas.

## 4. Preguntas abiertas

Se plantearán **cuando haga falta decidirlas**, no antes.

| # | Pregunta | Se decide en | Propuesta inicial |
|---|---|---|---|
| Q1 | ¿Argo CD o Flux? | F1 | ✅ **Argo CD** (ADR 0007) |
| Q2 | ¿Secretos con ESO + 1Password o con Sealed Secrets? | F1 | ✅ **ESO + 1Password** (ADR 0008) |
| Q3 | ¿TLS con Let's Encrypt (DNS-01) o CA interna? | F1 | ✅ **Let's Encrypt DNS-01 en Route 53** (ADR 0009) |
| Q4 | ¿El motor de agentes sigue siendo solo Claude por API? | F5 | Sí, con un *workspace* dedicado y límite de gasto |
| Q5 | ¿Usamos los agentes de IA de Port con tu propia clave LLM? | F3/F5 | A evaluar con el límite de uso del plan Free |
| Q6 | ¿Langfuse sí o no? ¿Dónde? | F6 | En docker01 si cabe; si no, solo obs-stack |
| Q7 | ¿Ampliar RAM del P500 con el presupuesto de 2026? | Tras F2 | Según el consumo real medido |

## 5. Registro de avance

| Fecha | Hito |
|---|---|
| 2026-10-23 | Arranque: visión, arquitectura, ADR 0001-0006 y pasos 00-03 documentados |
| 2026-10-24 | Paso 00: docker01 a 24 GiB con hugepages de 1 GiB y NUMA (a mano); `homelab-terraform` alineado sin drift |
| 2026-10-24 | Paso 01a: plantilla Debian 13 cloud-init (9013) · Paso 01: VM k3s01 creada con Terraform |
| 2026-10-24 | Paso 02: k3s `v1.36.5+k3s1` en marcha; línea base del nodo 75-93m CPU y 752 MiB (8 %) |
| 2026-10-24 | Paso 03: repo publicado en la org; org de Port creada y credenciales en 1Password · F1 decidida (ADR 0007-0009) |
| 2026-10-24 | Paso 04: bóveda `agentic-lab`, service account de solo lectura y usuario IAM de Route 53 verificados (✅ ✅ ⛔) · `platform-gitops` preparado (Argo CD 10.10.5, ESO 2.13.0) |
| 2026-10-24 | Paso 05: Argo CD autogestionado, ESO y `ClusterSecretStore` sanos (incidencia: token con `\n` por `op read` sin `-n`) · PR 1 de TLS preparado · ADR 0010 |
| 2026-10-25 | PR 1 de TLS fusionado (comodín staging OK) · PR 2 preparado · Kyverno/cuotas aplazados · F2 decidida (ADR 0011-0014) |
| 2026-10-26 | F2.1-F2.3: código, CI de PR, release-please y publicación firmada en GHCR (lección: CVE críticas de Alpine en el front) |
| 2026-10-27 | F2.4a: Meridian Orders en `orders-dev` solo por GitOps (CNPG sano, migración aplicada, API `0.1.0 · dev`) · ADR 0015 |
| 2026-10-28 | F3.4c: Argo CD confirma los despliegues en Port (webhook saliente, URL solo en 1Password). Incidencias: título de webhook > 30 caracteres; anotaciones de suscripción con valor vacío no llegaban desde el ApplicationSet |
| 2026-10-27 | F3.1: modelo de Port aplicado desde CI por OIDC (incidencia: el repo usa *sujetos inmutables* en el token OIDC) · F3.2: GitHub Ocean con *mapping* como código (37 PR, 106 ejecuciones) · F3.4a: linaje de lo aprobado; los 6 `workload` con `in_sync=true` y firma verificada por la plataforma · F3.3: exportador de Kubernetes en `k3s01` (RBAC mínimo; 6 `workload` con la imagen en ejecución) |
| 2026-10-27 | F3 decidida: demo en tres actos (B → D → cierre), linaje mixto, Port en Terraform (ADR 0016-0017) · paso 07 preparado |
| 2026-10-27 | F2.4b: CD en marcha. Dev automático (bot #5 y #6 con auto-merge), staging `0.1.0` (#7 + alta #8) y prod `0.1.0` con aprobación del entorno (#9 + alta #10). Incidencias: carrera tag/firma en la release y error OIDC transitorio en `cosign sign` (corregidas). **Fase 2 cerrada** |
