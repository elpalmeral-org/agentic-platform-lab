# Prompts probados · con su resultado real

> Ninguna petición de aquí es hipotética: cada una se ha ejecutado de verdad al menos una vez, con
> el resultado real anotado. Si se repite en una demo, el resultado puede variar (los modelos no
> son deterministas) — lo que no varía es que el *gate* de seguridad, si hay un hallazgo real, lo
> va a encontrar.

## Escenario principal del acto 2 (D2 · D3) · filtrar pedidos por correo

**Petición** (motor B, `/feature`):

> "Atención al cliente necesita encontrar los pedidos de un cliente concreto sin conocer su id.
> Añade un filtro por correo del cliente a `GET /api/orders`."

**Cambio:** `filtrar-pedidos-por-email` · **Nombre en kebab-case:** `filtrar-pedidos-por-email`

**Resultado real** (F4.5, 13-nov-2026):
- Fase A (PROPOSE): `proposal.md`/`design.md`/*delta spec* con *grounding* real. PR #28, fusionado.
- Fase B, 1ª ronda: `security-gate` → **FAIL** real. Hallazgo: `customer_email` (dato C3) en claro
  en el log de acceso de `uvicorn`.
- Primer arreglo (regex en el log) → **FAIL** otra vez: evitable con *percent-encoding* del nombre
  del parámetro; además fuera del alcance de `design.md` (bloqueado también por `spec-validator`).
- Vuelta a PROPOSE: enmienda real (`--no-access-log` + `hide_parameters=True`). PR #30, fusionado.
- Fase B, 2ª ronda: los tres validadores → **PASS**. PR #31, fusionado. Cambio archivado.

**Por qué este y no otro:** tiene un *gate* que bloquea de verdad, con una causa raíz real
(no un "a propósito dejamos un bug") y una corrección estructural, no un parche superficial — el
argumento completo del acto 2 en un solo ejemplo.

## Escenario de repuesto · trazas OTel del backend (si el principal ya está "limpio")

**Petición** (motor B, `/feature`):

> "F6 necesita que el backend emita trazas OTel hacia el obs-stack de la plataforma, sin que la
> query string de la petición llegue a las trazas."

**Resultado real** (F6.1, 13-nov-2026): instrumentación manual con un `server_request_hook`
(no *zero-code*, que no permite *hooks*); PASS directo, sin ronda de corrección — útil para
mostrar que no todas las *features* encuentran un *gate* en rojo, y que eso también es un
resultado válido.

## Escenario del motor abierto (D2-bis) · prueba de humo F4.7

**Petición** (idéntica para OpenRouter y Bonsai, vía `POST /api/harness/v1/responses`,
`metadata.harness_id` del rol `meridian/spec-writer`):

> "Responde solo con una frase: ¿qué harías primero si te pidiera una spec OpenSpec para añadir un
> filtro por teléfono a GET /api/orders?"

**Resultado real** (F4.7, 13-nov-2026):

| | OpenRouter | Bonsai |
|---|---|---|
| `connection` | `openrouter` | `bonsai` |
| `served_model` | `openai/gpt-5.4-mini` | `bonsai` |
| Coste | 0,0068 $ | 0 $ |
| Latencia | segundos | ~19 s |
| Respuesta | "Primero haría el grounding: leería la documentación aplicable..." | "Haría grounding: aplicaría la skill `corporate-grounding`, leería..." |

Las dos respuestas son coherentes con el mandato real de `spec-writer` (mencionan el *grounding*
como primer paso) — útil para el argumento de "mismo contrato, dos motores, sin *lock-in*".

## Si se necesita un escenario nuevo en directo

No improvisar un *prompt* sin probarlo antes. Si hace falta uno nuevo para la demo:
1. Probarlo primero con el motor B (`/feature`) en un entorno que no sea la demo en directo.
2. Anotar aquí el resultado real, con el número de PR, antes de usarlo delante de un cliente.
3. Preferir peticiones con un hallazgo real de algún validador: son las que mejor sostienen el
   argumento de gobierno — un PASS a la primera también es un resultado válido, pero menos
   memorable.
