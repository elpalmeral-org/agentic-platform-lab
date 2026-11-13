# ADR 0035 · Golden path para crear un servicio nuevo

- **Estado:** Aceptada · 2026-11-14 · desarrolla [01-arquitectura](../01-arquitectura.md) y el [roadmap](../02-roadmap.md) (D1 de la demo)

## Contexto

Hasta ahora el lab solo tiene un servicio (`meridian-orders`), y buena parte de la plataforma se
construyó asumiendo esa unicidad: nombres de repo/namespace/entidad de Port escritos a fuego en
varios sitios. D1 de la demo ("crear un servicio desde Port") quedó aplazado explícitamente por
eso mismo. Se pide un *golden path* real: elegir frontend, backend y dónde ejecutar (hoy, cada uno
con una sola opción válida), que genere un repo listo para AIDLC/harness y lo necesario en k3s01
para desplegarlo — y que lo mismo se pueda hacer a nivel de plataforma (autoservicio en Port), no
solo a mano.

Investigación real antes de diseñar nada (tres exploraciones en paralelo contra
`meridian-orders`, `platform-gitops` y los mecanismos reales de Port/harness):

1. **Tres piezas de `platform-gitops` están hoy cableadas a un solo servicio** y romperían con un
   segundo: `scripts/validate.sh` (constantes `OVERLAYS`/`APPSET`/`SIGNER`), el *mapping* de
   GitHub Ocean en `addons/port-k8s-exporter.yaml` (`startswith("meridian-")` y
   `relations.service: "meridian-orders"` literales), y `scripts/port-lineage.sh` +
   su *workflow* (mismas constantes). Generalizarlas es necesario para que un segundo servicio
   funcione, no una mejora opcional.
2. **El harness y HarnessRouter ya son genéricos por organización, no por servicio.** `apm
   install`/`apm compile` no necesitan nada más por repo que `apm.yml` con el pin — generan
   `.claude/`, `AGENTS.md`, etc. automáticamente. El paquete Rego `meridian.pr_gates` y los roles
   `meridian/<rol>` de HarnessRouter son productos **del harness**, compartidos por cualquier
   repo que lo consuma — el nombre "meridian" ahí es la marca del harness, no de "Orders" (lo
   confirma el propio comentario de `pr_gates.rego`: "repos de producto de Meridian").
3. **Port no tiene un nodo nativo de "crear repo desde plantilla".** Su propia guía oficial
   (`docs.port.io/guides/.../scaffold-a-new-service-with-port-workflows`) usa el mismo patrón que
   ya usan `pedir-feature`/`promote-meridian-orders` en este lab: `SELF_SERVE_TRIGGER` →
   `INTEGRATION_ACTION`/`dispatch_workflow` contra un *workflow* real de GitHub Actions.
4. **La *action* oficial de Port para esto, `cookiecutter-gha`, exige un PAT personal** para crear
   el repo (`action.yaml` real: "supporting only PATs at this time") — incompatible con el
   principio ya aplicado en el lab de no atar automatización a una cuenta personal (ADR 0027, para
   las firmas de *cosign*).
5. El *ruleset* de `meridian-orders` (`ci-ok`, `conventional-commits`, `harness-ok`, *squash*
   únicamente) se creó a mano por la API de GitHub (`gh api -X POST .../rulesets`, paso 08 del
   setup) — no por Terraform. Mecanismo plenamente repetible por *script*.

## Decisión

1. **Namespace independiente por servicio**, sin heredar el prefijo `meridian-`. Ese prefijo
   resultó ser específico de "Orders" al nacer con un solo servicio, no una marca de familia
   deliberada; los mecanismos que de verdad son compartidos (roles del harness, política OPA) ya
   no dependen de él.
2. **GitHub App dedicada `elpalmeral-scaffolder`**, `Administration: write` a nivel de
   **organización** (imprescindible para crear repos nuevos; no existe un alcance más fino) y
   nada más — mismo principio ya aplicado (`elpalmeral-platform-bot`, `elpalmeral-arc-runners`):
   una identidad, un propósito. Es el primer secreto del lab con alcance de organización, no de un
   repo concreto.
3. **Cookiecutter (la herramienta) para plantillar, no `cookiecutter-gha` (la *action* de Port).**
   Se separan las dos responsabilidades: la App dedicada crea el repo vacío por la API normal de
   GitHub (los tokens de GitHub App sí valen para eso); un *script* propio ejecuta `cookiecutter`
   sobre el repo ya creado.
4. **Repo plantilla `elpalmeral-org/service-template`**, derivado de `meridian-orders` sin el
   dominio de negocio (pedidos): nace como un esqueleto que arranca, pasa
   `/healthz`/`/readyz`/`/metrics`, sin ninguna entidad de negocio asumida. Solo se plantillan con
   Jinja2 los puntos reales donde "meridian-orders"/"meridian_orders" aparece como *string*
   (`apm.yml`, nombres de paquete, `Dockerfile`×2, `openspec/config.yaml`, el identificador de
   entidad de Port en `harness-ok.yml`, el `repositories:` del token en `harness-upgrade.yml`).
   Todo lo que ya es genérico por organización (ficheros de `apm install`, roles `meridian/<rol>`)
   se deja tal cual.
5. **Un único *workflow*, `crear-servicio.yml` (en `agentic-platform-lab`), para los dos canales**
   (Port y CLI directa) — mismo patrón que `aidlc-propose.yml`: Port solo dispara el mismo
   mecanismo que cualquiera con acceso al repo puede disparar a mano
   (`gh workflow run crear-servicio.yml -f ...`).
6. **El PR que abre en `platform-gitops` no se autofusiona.** Igual que cualquier cambio de
   infraestructura compartida en este lab, lo revisa y fusiona una persona (o yo, con confirmación
   explícita de turno).
7. **Ampliar la instalación de `elpalmeral-arc-runners` a un servicio nuevo (si ese servicio
   necesita el motor A) es una decisión aparte, con su propia confirmación** — no se hace dentro
   del *workflow* de creación sin pararse a confirmarlo, porque amplía el alcance de una identidad
   que hoy está deliberadamente acotada a un solo repo (ADR 0031).

## Consecuencias

- ✅ El segundo servicio real que se cree con este mecanismo es, a la vez, la prueba de que la
  generalización de `platform-gitops` (punto 1 del contexto) funciona de verdad con más de un
  servicio — no hay forma de probarlo sin crear uno.
- ✅ Ninguna automatización nueva depende de una cuenta personal, ni siquiera para crear repos.
- ⚠️ `elpalmeral-scaffolder` es, a propósito, la credencial con el alcance más amplio del lab
  hasta ahora (organización, no repo). Se crea solo cuando haga falta de verdad (antes de la
  primera ejecución real), no por adelantado.
- ⚠️ El catálogo de frontend/backend/*runtime* tiene hoy una sola opción válida en cada campo — el
  formulario ya está construido con `enum`, así que ampliarlo más adelante es añadir valores, no
  rediseñar nada.
