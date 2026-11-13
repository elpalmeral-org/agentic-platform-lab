# ADR 0033 · F4.7: conectar OpenRouter y Bonsai, publicar los 5 roles, prueba de humo

- **Estado:** Aceptada · 2026-11-13 · desarrolla [01-arquitectura](../01-arquitectura.md) §5 y el [roadmap](../02-roadmap.md) F4.7

## Contexto

F4.7 queda desbloqueado: Pablo confirmó explícitamente proceder, aceptando el gasto real de la
clave de OpenRouter (10 $, sin recarga) y el uso de un *slot* de Bonsai (compartido con Hermes).

Investigación real contra la API desplegada (`https://uhp.apl.elpalmeral.es`) y el repo real
(`github.com/HarnessRouter/harnessrouter`) antes de diseñar nada:

1. **Prefijo real de la API: `/api/harness/v1/...`, no `/v1/...`.** Verificado con una llamada
   real: `GET /api/harness/v1/harnesses` → `401 {"detail":"sign in to continue"}` (JSON, la API de
   verdad); `GET /v1/harnesses` (sin prefijo) → `307` a `/login` (cae en el *router* de la Console
   web). **`aidlc-propose.yml`/`aidlc-implement.yml` (F5) llaman a la ruta equivocada** — se
   corrigen en este ADR.
2. **Autenticación: `Authorization: Bearer <clave>`.** Verificado con una llamada real sin gastar
   nada: con la cabecera puesta (clave inventada), el error cambia de `"sign in to continue"` a
   `"missing or invalid API key"` — confirma que el servidor reconoce el mecanismo antes de tener
   la clave real.
3. **Crear la clave de API: solo manual, en la Console web** (Sign in → API Keys → Create). No hay
   endpoint REST para esto. Paso humano único de Pablo, con `HR_AUTH_USER`/`HR_AUTH_PASSWORD` ya en
   1Password desde F4.6.
4. **Conexión de un proveedor compatible con OpenAI** (`HR_SECRET_GLOBAL_HARNESS_CONN_<NOMBRE>`):
   confirmado con cita literal de `docs/self-hosting-guide.md`:
   `{"name":"...","provider":"openai","api_key":"...","base_url":"https://.../v1"}`. El proyecto
   también lista `openrouter` como proveedor nativo en su tabla de compatibilidad, pero **sin un
   ejemplo literal** de ese JSON — se usa la forma `provider: "openai"` + `base_url`, que SÍ está
   citada textualmente, no la nativa sin verificar.
5. **`HR_SECRET_GLOBAL_HARNESS_POLICY_<BACKEND>`** fija la cadena de conexiones de un *backend*
   (ejemplos citados: `CLAUDE`, `CODEX`, `HERMES` — que, según la propia documentación de
   `GET /v1/bases`, son *bases* reales del producto, no nombres de ejemplo genéricos). **El nombre
   para nuestro *backend* real, `OPENCODE`, no está citado textualmente** — es una inferencia por
   el patrón, pendiente de verificar con `GET /v1/models` tras desplegar.
6. **Publicar un harness: `POST /v1/harnesses`**, cuerpo `HarnessBody` (esquema real, del
   `openapi.json` de la propia instancia): únicos campos obligatorios `name` (texto libre, **no**
   es un identificador buscable) y `base`; el resto opcional (`system_prompt`, `default_model`,
   `disabled_tools`, `max_step`, `timeout_seconds`, `reasoning_effort`, …). La respuesta es
   `additionalProperties: true` (sin esquema fijo documentado) — el `id` real que asigna el
   servidor solo se conoce leyendo la respuesta real de la creación.
7. **Ejecutar un harness: `POST /v1/responses`**, cuerpo `CreateResponseBody` (esquema real):
   `input`, `model`, `metadata` (objeto libre — `metadata.harness_id` es el campo real para elegir
   el harness, confirmado con cita de la guía), `stream`, `background`, `max_output_tokens`,
   `reasoning`, `backend`. Respuesta con `id` (`resp_...`), `status`, `output`, `usage`
   (`input_tokens`/`output_tokens`/`total_tokens`). **Esta es la llamada que gasta dinero de
   verdad** contra OpenRouter.
8. **Verificación de solo lectura disponible antes de gastar nada**: `GET /v1/models` ("Global
   model catalog... every backend's available models + default") y `GET /v1/bases` — ambas Bearer,
   gratis, permiten confirmar que una conexión quedó bien resuelta antes de la primera llamada real
   a `/v1/responses`.
9. **Nombres de herramienta de `disabled_tools` para la base `opencode`**: sin lista cerrada en la
   documentación disponible (el esquema real es un array sin tipo de item restringido). La lista
   provisional de `uhp/roles.yaml` (`[write, edit, bash]`) sigue sin verificar contra la instancia
   real; queda fuera de alcance de F4.7 confirmarla (los roles ya definen la intención, no bloquea
   la prueba de humo).

## Decisión

1. **Conexiones**: `HR_SECRET_GLOBAL_HARNESS_CONN_OPENROUTER` (clave real, vía `ExternalSecret` con
   plantilla de ESO — nunca a mano) y `HR_SECRET_GLOBAL_HARNESS_CONN_BONSAI` (sin secreto real:
   LAN interna, `api_key` de relleno) en el `StatefulSet` de HarnessRouter.
   `HR_SECRET_GLOBAL_HARNESS_POLICY_OPENCODE={"chain":["openrouter","bonsai"]}` como mejor
   suposición verificable — **se confirma o corrige con `GET /v1/models` después de desplegar, no
   antes de tener ese dato real**.
2. **Secuencia de verificación, de menor a mayor gasto** (ninguno de los tres primeros pasos gasta
   nada ni ocupa un *slot* de Bonsai):
   1. `GET /v1/models` y `GET /v1/bases` (Bearer, gratis) para confirmar que las conexiones y la
      *policy* quedaron bien resueltas.
   2. `POST /v1/harnesses` (gratis, solo metadatos) para publicar los 5 roles de `uhp/roles.yaml`
      como `meridian/<rol>@X.Y.Z`, uno por uno, guardando el `id` real que devuelve cada creación.
   3. **Una única llamada real** a `POST /v1/responses` contra `meridian/spec-writer` por
      OpenRouter, con un *prompt* mínimo — el primer gasto real, señalado explícitamente antes de
      ejecutarse.
   4. Una llamada equivalente contra el mismo rol por Bonsai (cambiando solo el modelo/conexión),
      comprobando antes que no hay otra sesión de Hermes en curso.
3. **Corrección de `aidlc-propose.yml`/`aidlc-implement.yml`** (bug real encontrado, no solo
   diseño): la URL debe llevar el prefijo `/api/harness`; la comprobación de publicación debe
   filtrar por `.name` (campo que controlamos), no por `.id` (lo asigna el servidor); y la llamada
   real necesita la cabecera `Authorization: Bearer` con la clave nueva (secreto de GitHub Actions
   en `meridian-orders`, mismo patrón que `OPENROUTER_API_KEY` en `agentic-platform-lab`).
4. **`harness-sync` vive en `platform-harness`**, como `workflow_dispatch` manual (no atado al
   *pipeline* automático de *release*): publicar en HarnessRouter es una acción deliberada y con
   coste, distinta de cortar una release firmada del harness. Lee `uhp/roles.yaml` + el mandato
   (`systemPrompt`) de cada `.apm/agents/<rol>.agent.md` + la versión de la última release.
5. **Comparación con el motor B**: se reutiliza el mandato ya probado en F4.5
   (`filtrar-pedidos-por-email`, o uno más simple si ese ya no aplica tal cual) para que la
   comparación sea sobre el mismo trabajo, no sobre tareas distintas.

## Consecuencias

- ✅ Cada paso de riesgo creciente es verificable por separado: un fallo de *policy* o de conexión
  se detecta en un `GET` gratis, antes de la primera llamada que cuesta dinero.
- ⚠️ `POLICY_OPENCODE` y los nombres reales de herramienta de `disabled_tools` siguen sin una cita
  textual que los confirme al 100 %; si `GET /v1/models` muestra que la *policy* no se aplicó, hay
  que investigar el nombre real antes de seguir (plan B: mirar la Console web, que sí renderiza los
  *backends* configurados, en vez de adivinar otra variable de entorno a ciegas).
- ⚠️ El presupuesto de OpenRouter (10 $) y el *slot* de Bonsai son recursos compartidos y no
  recargables: la prueba de humo usa el mínimo de llamadas necesario, no una batería de pruebas.
