# ADR 0032 · F6: reutilizar el obs-stack existente, sin Langfuse; coste de OpenRouter en Port

- **Estado:** Aceptada · 2026-11-13 · desarrolla [01-arquitectura](../01-arquitectura.md) §5 y el [roadmap](../02-roadmap.md) F6

## Contexto

F6 pide trazas y coste por agente, visibles en Grafana y en Port (Q6 abierta: ¿Langfuse sí o no, y
dónde?). Investigación real antes de diseñar nada (no asumida):

1. **Ya existe un obs-stack real en docker01** (`homelab-containers/obs-stack`): ClickHouse 24.8,
   OTel Collector contrib 0.144.0 (OTLP gRPC `:4317` / HTTP `:4318`, publicados en el host →
   `192.168.0.6`), Grafana 11.0.0, Prometheus v2.51.0. Retención real en ClickHouse (por
   `engine_full`/TTL): 30 días trazas/logs, 90 días métricas.
2. **Ya hay un precedente directo**: `homelab-containers/ai-stack/OBSERVABILITY.md` instrumentó
   Open WebUI contra este mismo *stack* con *push* OTLP nativo, con el principio explícito **"el
   servicio nuevo no despliega infraestructura de observabilidad, solo emite telemetría"**.
3. **Langfuse ya se evaluó y se descartó una vez, por un motivo que sigue vigente**: la tabla de
   alternativas de ese mismo documento lo descartó porque autohospedarlo exige Postgres + Redis +
   ClickHouse + S3 propios — duplicar ClickHouse en un host con RAM/GPU ya comprometidas con Bonsai
   no compensa. Verificado ahora contra `langfuse.com/self-hosting`: sigue siendo así, sin opción
   documentada de reutilizar un ClickHouse externo. Sí acepta OTLP/HTTP directo en
   `/api/public/otel` sin su SDK, pero eso no cambia el problema de infraestructura.
4. **HarnessRouter CE no emite OTel, por diseño**: desactiva explícitamente el *telemetry* de
   producto, sin variables `OTEL_*` ni `/metrics`. Soporta W3C Trace Context si quien llama ya trae
   traza, pero no la emite. Su observabilidad es **por API**: `GET /v1/traces/{session}/all` y
   `GET /v1/sessions/{session}/turns` (con coste por turno) — para aparecer en el *stack* haría
   falta un puente propio (*poll* → *push* OTLP), y hoy no hay ninguna ejecución real del motor A
   que trazar (F4.7 sigue pendiente de confirmar).
5. **OpenRouter expone el consumo de la clave por API, de solo lectura**: `GET
   https://openrouter.ai/api/v1/key` (con la propia clave como *bearer*) devuelve `usage`,
   `usage_daily/weekly/monthly` y `limit_remaining`. No gasta presupuesto (no es una llamada de
   *completion*), pero exige tener la clave disponible en el sitio desde donde se consulte.
6. **meridian-orders backend parte de cero**: sin `opentelemetry` en `pyproject.toml`, sin
   *middleware*. **Conectividad verificada de verdad** (no asumida): un *pod* efímero de
   diagnóstico en k3s01 (`curlimages/curl`, borrado solo) contra
   `http://192.168.0.6:4318/v1/traces` devolvió `HTTP/1.1 200 OK` desde la red de *pods* — el mismo
   patrón LAN que ya usa HarnessRouter para llegar a Bonsai.

## Decisión

1. **Sin Langfuse.** Se reutiliza el obs-stack de docker01 tal cual está, sin desplegar
   infraestructura nueva — mismo principio que ai-stack. Se reconsiderará Langfuse solo si la
   observabilidad de conversación completa (prompt/respuesta, coste por usuario) se vuelve
   prioritaria, p. ej. al poner un agente en producción real con tráfico de usuarios externos.
2. **F6.1 · Instrumentar meridian-orders con OpenTelemetry** (FastAPI + SQLAlchemy
   auto-instrumentation, exportador OTLP) apuntando a `http://192.168.0.6:4317`, con
   `OTEL_RESOURCE_ATTRIBUTES` marcando `environment=dev|staging|prod` para distinguir entornos en
   los mismos *dashboards*. No es secreto (es una IP interna de la LAN), así que va directo en el
   manifiesto, no en 1Password/ESO. Un *dashboard* de Grafana para el servicio, siguiendo el patrón
   ya usado por ai-stack (métricas + explorador de trazas contra ClickHouse).
3. **F6.2 · Coste de OpenRouter visible en Port**, no en Grafana: un blueprint nuevo
   `openrouter_usage` (singleton, no por servicio — la clave es de la plataforma, no de
   meridian-orders) + un *workflow* programado (cron diario, mismo patrón que
   `harness-upgrade.yml`) que llama a `GET /v1/key` y publica `usage`/`limit_remaining`. Vive en
   `agentic-platform-lab` (donde ya está el OIDC de Port), en un *runner* de GitHub estándar
   (`ubuntu-latest`): tanto `openrouter.ai` como la API de Port son accesibles por Internet, sin
   necesitar LAN ni ARC.
4. **El puente HarnessRouter → OTel se difiere hasta F4.7.** No se construye un *poll* contra una
   API que hoy no tiene ninguna sesión real que listar; se revisita cuando F4.7 publique roles y
   conecte un proveedor.
5. **Motor B (Claude Code) no tiene coste por token que trazar aquí**: es suscripción personal, no
   facturación por uso. F6 no necesita instrumentarlo; su "coste" ya es fijo y conocido.

## Consecuencias

- ✅ No se duplica infraestructura de observabilidad ni se compromete más RAM/GPU de docker01
  (coherente con Q7 seguir abierta, no agravada).
- ✅ F6.1 no depende de F4.7 ni gasta nada: es observabilidad de la app, no de los agentes.
- ⚠️ **F6.1 sí es un cambio real sobre infraestructura compartida**: fusionar en `meridian-orders`
  dispara CI/CD real y toca el *pod* en ejecución de `orders-dev` (nueva dependencia, nuevo tráfico
  saliente hacia docker01). Por la regla permanente de CLAUDE.md §6, se implementa en una rama y se
  **para a confirmar antes de fusionar a `main`**, no antes.
- ⚠️ **F6.2 necesita un secreto nuevo que Pablo debe crear él mismo**: la clave de OpenRouter
  (capaz de gastar el presupuesto, aunque esta llamada en concreto sea de solo lectura) tendría que
  vivir también como secreto de GitHub Actions en `agentic-platform-lab`
  (`agentic-lab/openrouter-api`, campo `credential`, ya en 1Password) — ampliar dónde vive una
  credencial con presupuesto limitado no es una decisión que tomar en solitario; se para a
  confirmar antes de pedírselo a Pablo.
- ⏸️ El coste del motor A (tokens/turno vía HarnessRouter) sigue sin visibilidad hasta F4.7; es una
  limitación conocida, no un olvido.
