# ADR 0030 · HarnessRouter CE en k3s01: `StatefulSet`, imagen por digest, sin configurar proveedores todavía

- **Estado:** Aceptada · 2026-11-13 · desarrolla la [ADR 0006](0006-uhp-harnessrouter-gateway.md) y la [ADR 0024](0024-harnessrouter-en-f4-proveedores.md) · F4.6

## Contexto

No había manifiestos de HarnessRouter CE escritos todavía (ADR 0006: «no hay chart de Helm ni guía
de Kubernetes»). Antes de escribirlos hacía falta investigar de verdad el proyecto real (imagen,
puertos, variables, requisitos de ejecución), no asumirlos: es infraestructura que se despliega en
el clúster real. Hallazgos verificados contra Docker Hub y la guía de *self-hosting* del proyecto:

- Imagen `harnessrouter/harnessrouter`, puerto **3000** (Console + Gateway + API, el único que se
  publica); 8080 (Gateway) y 8081 (Runner) son *loopback* interno del propio contenedor, nunca se
  exponen.
- Dato de un solo volumen, `/data` (BD, credenciales cifradas, *workspaces*): **un réplica por
  volumen**, nunca varias compartiéndolo.
- **El contenedor exige arrancar como root** («refuses to start any other way» desde la 0.8.2): el
  *runtime* baja privilegios por sesión de agente dentro del propio contenedor (aislamiento por
  usuario del SO, no por contenedor). Sin capacidades Linux extra: nada de `--privileged` ni
  `--cap-add`.
- Variables relevantes: `HR_BACKENDS` (lista de bases a instalar, csv), `HR_SECRET_KEY` (cifra las
  credenciales guardadas; debe sobrevivir a reinicios y *upgrades*), `HR_AUTH_USER`/
  `HR_AUTH_PASSWORD` (login de la Console).
- Variables `HR_SECRET_GLOBAL_HARNESS_CONN_<nombre>`/`HR_SECRET_GLOBAL_HARNESS_POLICY_<nombre>`
  permiten configurar conexiones de proveedor por variable de entorno (sin pasar por el navegador),
  lo que resuelve la preocupación de la ADR 0006 de cómo versionar la configuración de harnesses —
  pero exigen conocer el esquema JSON exacto por proveedor (confirmado solo para `anthropic` en la
  documentación encontrada); **no se usan en este paso** (ver Decisión 5).

## Decisión

1. **`StatefulSet`, una réplica, `PersistentVolumeClaim` de 15 GiB** (`local-path`), montado en
   `/data`. Namespace propio `harnessrouter`.
2. **Imagen fijada por digest**: `harnessrouter/harnessrouter@sha256:d6697b27b23a4a4ee30f88edc1668fb49b8c10597617e4c4c3c5ad0a25b9c6e6`
   (tag `0.41.13` en el momento de escribir esto, resuelto con `docker manifest inspect` contra
   Docker Hub — el mismo digest que reporta `GET /v2/.../tags/0.41.13` de la API de Docker Hub).
3. **Contexto de seguridad sin `runAsNonRoot`**: se mantiene `allowPrivilegeEscalation: false`,
   `capabilities.drop: ["ALL"]` y `seccompProfile: RuntimeDefault` (compatibles con arrancar como
   root), pero **no** se fija `runAsUser` ni `runAsNonRoot: true` — el contenedor lo rechazaría. Es
   la única excepción a la plantilla de seguridad que usan los demás *Deployments* del repo
   (`apps/meridian-orders/base/backend.yaml`), y por una razón documentada del propio proyecto, no
   por comodidad.
4. **Solo el puerto 3000 se expone** (`Service` + `Ingress`); 8080/8081 no tienen ni `Service`.
   `uhp.apl.<dominio>` ([ADR 0010](0010-nombres-publicos-gitops-y-doh.md)), cubierto por el
   certificado comodín de Traefik ya existente: sin `Certificate` propio.
5. **Credenciales por `ExternalSecret`** desde `agentic-lab/harnessrouter` (1Password, ya creado en
   el paso 08.5): `HR_AUTH_USER` (campo `username`), `HR_AUTH_PASSWORD` (campo `password`),
   `HR_SECRET_KEY` (campo `secret_key`).
6. **`HR_BACKENDS` mínimo**: `opencode,vibe,fast-agent` (las bases del motor A ya decididas en el
   paso 08.6 — `uhp/roles.yaml` solo usa `opencode` hoy; `vibe`/`fast-agent` quedan listas para
   cuando algún rol pase a Bonsai).
7. **Alcance de este paso: desplegar y comprobar que arranca y responde, nada más.** No se
   configura ninguna conexión de proveedor (OpenRouter, Bonsai) todavía: eso es F4.7
   («`harness-sync` + prueba de humo»), que necesita investigar el esquema JSON exacto de
   `HR_SECRET_GLOBAL_HARNESS_CONN_*` para un proveedor *OpenAI-compatible* genérico (OpenRouter no
   es Anthropic) antes de escribir nada, y gasta la clave de OpenRouter real.
8. **Sin tocar el host** (hardening de `fs.protected_hardlinks` o bloqueo de `169.254.169.254` que
   sugiere la guía): es una recomendación para instalaciones Docker de un único nodo expuesto;
   aquí es un Pod normal de k3s01 sin `hostNetwork`, y tocar el host significa Terraform, fuera de
   alcance (`k3s01.tf` tiene `ignore_changes = all`).

## Consecuencias

- ✅ Nada de esto estaba inventado: cada dato (imagen, puertos, variable, digest) viene de la
  documentación real del proyecto o de la API de Docker Hub, verificado, no asumido.
- ✅ Separar "desplegar" (F4.6) de "conectar proveedores y gastar dinero" (F4.7) deja un punto de
  control claro antes de tocar la clave de OpenRouter o la GPU compartida con Hermes.
- ⚠️ Memoria de k3s01: con los límites de este paso (*request* 1 GiB / límite 3 GiB, ya decididos
  en el paso 08.6), la suma de límites del clúster pasa a ~116 %. Aceptado por Pablo para F4.6;
  vigilar OOM, una sola sesión de agente a la vez.
- ⚠️ El contenedor arranca como root: es una excepción deliberada y documentada a la plantilla de
  seguridad del repo, no una relajación general.
