# 01 · Arquitectura objetivo

> Este documento describe **a dónde vamos**. Lo que está construido en cada momento lo marca el
> [roadmap](02-roadmap.md). Las piezas marcadas *(propuesto)* están pendientes de decisión.

## 1. Vista de contexto

```mermaid
flowchart TB
    subgraph USERS["Personas"]
        PABLO["Pablo / presentador<br/>Mac · VPN WireGuard"]
        CLI["Cliente<br/>mira la pantalla"]
    end

    subgraph SAAS["Internet · SaaS"]
        PORT["Port.io<br/>IDP (Free · región EU)"]
        GH["GitHub<br/>org pública · Actions · GHCR"]
        ANT["API Anthropic<br/>Claude"]
    end

    subgraph HOME["Homelab · LAN"]
        subgraph PVE["Proxmox · hyper02"]
            subgraph D1["docker01 · VM existente"]
                DNS["Technitium DNS"]
                OBS["obs-stack<br/>OTel · ClickHouse · Grafana"]
                TRF["Traefik"]
            end
            subgraph K["k3s01 · VM nueva"]
                ARGO["Argo CD"]
                HR["HarnessRouter<br/>UHP"]
                ARC["ARC<br/>runners efímeros"]
                EXP["Port k8s exporter<br/>+ Ocean Argo CD"]
                APPS["meridian-orders<br/>dev · staging · prod"]
            end
        end
    end

    PABLO -->|navegador| PORT
    PABLO -->|kubectl · navegador| K
    CLI -.-> PABLO
    ARGO -->|pull HTTPS| GH
    ARC -->|long-poll HTTPS| GH
    HR -->|HTTPS| ANT
    EXP -->|push HTTPS| PORT
    PORT -->|dispara workflows| GH
    K -->|OTLP| OBS
    K -->|resuelve nombres| DNS
```

**Principio de red: todo sale, nada entra.** Ninguna pieza del homelab necesita estar expuesta a
Internet: Argo CD *tira* de GitHub, los runners ARC hacen *long-poll* a GitHub, el exporter de Port
*empuja* a Port y HarnessRouter *llama* a Anthropic. Port solo habla con GitHub, nunca con el
clúster. La demo se conduce desde el Mac por VPN.

```mermaid
flowchart LR
    subgraph LAN["LAN / VPN"]
        K3S["k3s01"]
        MAC["Mac"]
    end
    GH["GitHub"]
    PORT["Port.io"]
    ANT["Anthropic"]
    K3S -- "saliente 443" --> GH
    K3S -- "saliente 443" --> PORT
    K3S -- "saliente 443" --> ANT
    PORT -- "API" --> GH
    MAC -- "LAN" --> K3S
    INET(("Internet")) -. "❌ sin puertos abiertos" .-x K3S
```

## 2. Repos y responsabilidades

```mermaid
flowchart LR
    subgraph ORG["GitHub · org pública"]
        LAB["agentic-platform-lab<br/>docs · setup · Port como código<br/>harness corporativo (fuente)"]
        APP["meridian-orders<br/>apps/backend (FastAPI)<br/>apps/frontend (Angular)<br/>openspec/ · harness.lock"]
        OPS["platform-gitops<br/>addons/ (plataforma)<br/>apps/meridian-orders/{dev,staging,prod}"]
    end
    GHCR[("GHCR<br/>imágenes firmadas")]
    ARGO["Argo CD"]

    LAB -->|"release del harness<br/>PR de upgrade"| APP
    APP -->|"CI: build · SBOM · cosign"| GHCR
    APP -->|"CD: PR de bump de imagen"| OPS
    OPS -->|reconcilia| ARGO
    ARGO -->|pull| GHCR
```

| Repo | Escribe en él | Nunca escribe en él |
|---|---|---|
| `agentic-platform-lab` | Pablo (PR) | Agentes de producto |
| `meridian-orders` | Desarrolladores y agentes AIDLC (siempre por PR) | Argo CD |
| `platform-gitops` | Workflow de CD (PR de promoción) y Pablo | Agentes AIDLC directamente |

> **Por qué el GitOps va aparte:** separa *qué se construye* de *qué se despliega*. Promocionar a
> producción es un PR revisable en otro repo, con otros permisos, y el agente que escribe código no
> tiene forma de tocar lo que corre en el clúster.

## 3. Dentro del clúster

```mermaid
flowchart TB
    subgraph K3S["k3s01 · un nodo"]
        subgraph SYS["kube-system (k3s)"]
            TRAEFIK["Traefik · ingress"]
            SLB["ServiceLB"]
            LP["local-path · PV"]
        end
        subgraph PLAT["Namespaces de plataforma"]
            NS_ARGO["argocd"]
            NS_ESO["external-secrets"]
            NS_CM["cert-manager"]
            NS_PORT["port-k8s-exporter · port-ocean"]
        end
        subgraph AGENT["Namespaces de agentes"]
            NS_HR["harnessrouter"]
            NS_ARC["arc-system · arc-runners"]
        end
        subgraph APPS["Namespaces de aplicación"]
            DEV["meridian-dev"]
            STG["meridian-staging"]
            PRO["meridian-prod"]
        end
    end
    TRAEFIK --> DEV & STG & PRO & NS_ARGO & NS_HR
    NS_ARC -->|"UHP (ClusterIP)"| NS_HR
```

Los entornos son **namespaces** del mismo clúster. Es suficiente para enseñar promoción GitOps y
aislamiento por políticas, y es lo que cabe en un nodo.

## 4. Flujo AIDLC de extremo a extremo

```mermaid
sequenceDiagram
    autonumber
    actor N as Negocio
    participant P as Port.io
    participant GA as GitHub Actions
    participant R as Runner ARC (k3s)
    participant U as HarnessRouter (UHP)
    participant C as Claude
    participant A as meridian-orders
    actor H as Humano revisor
    participant O as platform-gitops
    participant AR as Argo CD

    N->>P: "Pedir feature" (lenguaje natural)
    P->>GA: workflow_dispatch aidlc-propose
    GA->>R: job en runner efímero
    R->>U: POST /v1/responses (harness spec-writer)
    U->>C: tarea con grounding
    C-->>U: cambio OpenSpec
    R->>A: PR con la spec
    H->>A: 🧑‍⚖️ Puerta 1: aprueba la spec
    A->>GA: aidlc-implement
    GA->>R: job en runner efímero
    R->>U: POST /v1/responses (harness implementer)
    U->>C: implementar contra la spec
    R->>A: PR con el código
    A->>GA: gates deterministas (runners de GitHub)
    A->>GA: gates agénticos (runner ARC → UHP)
    H->>A: 🧑‍⚖️ Puerta 2: aprueba el merge
    A->>GA: build · SBOM · cosign → GHCR
    GA->>O: PR de promoción a dev
    O->>AR: merge → reconcilia
    AR-->>P: estado del despliegue (Ocean)
```

## 5. Dónde corre cada tipo de job

Los repos son públicos y los **runners self-hosted en repos públicos son un riesgo** conocido
(cualquier PR de un fork podría ejecutar código en tu LAN). La regla es:

```mermaid
flowchart TD
    J["Job de CI"] --> Q1{"¿Necesita algo<br/>de la LAN?<br/>(UHP, clúster)"}
    Q1 -- No --> GHR["Runner hospedado de GitHub<br/>(gratis e ilimitado en repos públicos)<br/>lint · tests · build · SBOM · firma"]
    Q1 -- Sí --> Q2{"¿Lo dispara alguien<br/>de la org?"}
    Q2 -- "Sí: workflow_dispatch,<br/>push a rama propia,<br/>PR del mismo repo" --> ARCR["Runner ARC efímero<br/>(un pod por job)"]
    Q2 -- "No: PR de fork" --> STOP["⛔ No se ejecuta<br/>aprobación obligatoria<br/>+ condición en el workflow"]
```

## 6. Presupuesto de recursos

El host tiene 62,7 GiB de RAM y 24 hilos. docker01 fija su RAM entera en memoria física (VFIO +
virtiofs), así que cada GiB que se le quita es un GiB real para k3s01.

| VM | Antes | Después | Comentario |
|---|---|---|---|
| docker01 | 32 GiB · 12 vCPU | **24 GiB** · 12 vCPU | A validar en el [paso 00](setup/paso-00-capacidad.md) |
| k3s01 | — | **10 GiB · 6 vCPU · 80 GB** | Nuevo |
| Resto (nas01, HA, PBS…) | sin cambios | sin cambios | — |

```mermaid
pie showData
    title Reparto objetivo de k3s01 (MiB)
    "k3s + Traefik + sistema" : 1500
    "Argo CD" : 1200
    "HarnessRouter + runners ARC (pico)" : 3500
    "Port exporter + Ocean" : 500
    "meridian-orders x3 entornos" : 1500
    "Margen" : 2040
```

> Langfuse no entra en este presupuesto. Si lo queremos, irá a docker01 junto al obs-stack o
> esperará a una ampliación de RAM (ver preguntas abiertas en el roadmap).

## 7. Nombres y DNS

Todos los servicios del lab cuelgan de un subdominio propio con *wildcard* hacia k3s01:

```
*.${LAB_SUBDOMAIN}.${LAB_DOMAIN}  →  ${K3S_IP}      (Traefik de k3s)
argocd.${LAB_SUBDOMAIN}.${LAB_DOMAIN}
uhp.${LAB_SUBDOMAIN}.${LAB_DOMAIN}
orders-dev.${LAB_SUBDOMAIN}.${LAB_DOMAIN}  …
```

Los valores reales están en `lab.env` (no versionado). Ver [`lab.env.example`](../lab.env.example).
