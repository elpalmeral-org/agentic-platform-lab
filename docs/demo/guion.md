# Guion · 30-40 min, tres actos que acaban donde empiezan

> Diseño general en [`README.md`](README.md). Este guion es la versión ejecutable: minuto a
> minuto, con lo que de verdad se ve en pantalla y lo que se dice. Nada aquí describe algo que no
> se pueda auditar en directo (ADR 0034).

Público tipo: CIO/CISO y arquitectura/*design authority*, a partes iguales. Un único servicio real
(Meridian Orders). Antes de empezar: `checklist-previo.md`.

## Acto 1 · Lo que corre en producción (0-5 min)

**Qué se ve:** la ficha de Meridian Orders en Port.

| Minuto | Pantalla | Qué se dice |
|---|---|---|
| 0:00 | Ficha del servicio, entorno `prod` | "Esto es lo que corre ahora mismo en producción: versión `0.1.0`." |
| 1:00 | Linaje: digest firmado, SBOM, CVE | "La imagen está firmada con *cosign*, sin identidad personal — la firma es del propio *workflow* de GitHub. El SBOM y las CVE están aquí, no en una hoja aparte." |
| 2:30 | PR de promoción a `prod` y su aprobador | "Esta versión llegó a producción por un PR de promoción, con un aprobador real del entorno `prod` de GitHub — la misma puerta que ya existía antes de meter agentes de por medio." |
| 4:00 | Scorecard `harness_governance` (Gold) | "El harness que usan los agentes sobre este repo también está versionado, firmado y auditado — igual que el código." |

**Mensaje CIO/CISO:** "Sé qué hay en producción, quién lo aprobó y que es lo aprobado."
**Mensaje arquitectura:** "Las reglas son código (`gitops-ok`) y valen igual para personas y bots."

**D4** (trazabilidad) empieza aquí: de la ficha al digest. Se cierra en el acto 3.

## Acto 2 · Un cambio en directo (5-30 min)

**Qué se ve:** el *workflow* «Pedir feature» de Port, con selector de motor.

### D2 · Pedir la feature

| Minuto | Acción | Qué se dice |
|---|---|---|
| 5:00 | Abrir «Pedir feature» en la ficha del servicio | "El negocio no escribe código: pide una *feature* en lenguaje natural." |
| 6:00 | Rellenar: `servicio=meridian-orders`, `motor=claude`, petición real (ver `prompts.md`) | "Elijo el motor Claude Code — la suscripción personal de la empresa, sin clave de API de pago por token. El motor abierto (OpenRouter/Bonsai) es la misma petición, mismo harness, sin *lock-in* — lo enseño aparte en un momento." |
| 7:00 | Se crea el *issue* `aidlc:claude` real en GitHub | "Esto es un *issue* de verdad, no una maqueta." |

### D2-bis · El motor abierto, en paralelo (sin PR autónomo todavía)

| Minuto | Acción | Qué se dice |
|---|---|---|
| 8:00 | Repetir «Pedir feature» con `motor=abierto` | "Mismo formulario, mismo contrato — ahora por HarnessRouter, con un *runner* efímero en el propio clúster." |
| 9:00 | Mostrar el *run* real en Port (`result`) y, si hace falta, una llamada real a `/v1/responses` desde la terminal | "El motor abierto ya habla de verdad con OpenRouter y, en local, con un modelo propio (Bonsai) — aquí está el coste real de la última prueba: menos de un céntimo." Si preguntan por el PR automático: "cerrar ese ciclo entero es el siguiente paso del *roadmap* — hoy el motor B es el que completa la propuesta de principio a fin." |

### D3 · El trabajo real con el motor B (Claude Code)

| Minuto | Acción | Qué se dice |
|---|---|---|
| 10:00 | `/feature` en el Mac con la petición real | "Fase A: propone la *spec* con *grounding* contra el corpus corporativo." |
| 14:00 | PR de la *spec* (puerta 1) | "Una persona aprueba la *spec* antes de que exista una línea de código." |
| 16:00 | Fase B: implementación + 3 validadores | "`spec-validator`, `security-gate`, `impl-conformance` — los tres de solo lectura." |
| 18:00 | **Un *gate* bloquea de verdad** | "Esto no es guion: la primera vez que se hizo esta *feature*, `security-gate` encontró que el dato se filtraba al log de acceso. Aquí está el hallazgo real, con la cita exacta del corpus de seguridad." |
| 22:00 | Vuelta a PROPOSE, corrección real, PR de código (puerta 2) | "La corrección no fue un *regex* tapando el síntoma — fue estructural: sin log de acceso para esa ruta, sin parámetros en los errores de base de datos." |

**D3** es el corazón del acto 2: un *gate* que de verdad frena un atajo de seguridad, con una
corrección real detrás, no un resultado prefabricado.

**Mensaje CIO/CISO:** "El negocio pide, las máquinas ejecutan, las personas deciden" — y sin
*lock-in*: la misma petición por dos motores.
**Mensaje arquitectura:** *spec* como contrato, harness versionado, los agentes proponen antes del
PR y las puertas son deterministas (ADR 0025).

## Acto 3 · Cierre (30-40 min)

**Qué se ve:** la misma ficha del acto 1, ahora con el cambio fusionado.

### D5 · Coste, antes que las aprobaciones

| Minuto | Pantalla | Qué se dice |
|---|---|---|
| 30:00 | Entidad `openrouter_usage` en Port | "Antes de hablar de quién aprobó qué: cuánto cuesta. Esta clave tiene un tope de 10 $, sin recarga — y esta demo ha gastado menos de 2 céntimos." |
| 32:00 | `harness_status` del servicio | "Versión del harness, firma verificada, sin *drift* — por ejecución, no una vez al trimestre." |

### D6 · El hilo completo de aprobaciones (opcional, si hay tiempo)

| Minuto | Pantalla | Qué se dice |
|---|---|---|
| 34:00 | PR de la *spec* → PR del código → PR de *release* (`chore(release): 0.2.0`, ya abierto) | "Tres aprobaciones humanas, tres personas distintas si hiciera falta, todas en el mismo hilo." |
| 36:00 | Fusionar el PR de *release* **de verdad** | "Esto dispara el *pipeline* real: construir, firmar, escanear, y promocionar a `prod` con la aprobación del entorno de GitHub." |
| 39:00 | Volver a la ficha del acto 1 | "Misma pantalla. Ahora dice `0.2.0`." |

**Mensaje CIO/CISO:** coste y responsabilidad medibles, por ejecución.
**Mensaje arquitectura:** trazabilidad de la *spec* al digest, de principio a fin.

> **D6 es la única acción de la demo que no se puede repetir sin preparación**: una vez fusionado
> el PR de *release*, hace falta una `chore(release)` nueva (se abre sola) antes de la siguiente
> demo. Confirmar en `checklist-previo.md` que el PR sigue abierto y que `publish.yml` pasa para
> los dos *apps* antes de prometer este paso en directo.

## Si sale mal en directo

- **El *gate* no bloquea** (alguien ya corrigió la *feature* de ejemplo): usar otra petición de
  `prompts.md` con un hallazgo real conocido, o mostrar la ejecución grabada del PR #28/#30/#31 de
  `meridian-orders` (reales, archivados en `openspec/changes/archive/`).
- **`publish.yml` falla por una CVE** (puede seguir pasando, F6.1): es un hallazgo real, no un
  fallo de la demo — "esto es exactamente lo que hace esta puerta: no deja pasar una imagen con una
  vulnerabilidad crítica, aunque sea inconveniente hoy."
- **HarnessRouter no responde**: el acto 2 sigue con el motor B solo; se menciona el motor abierto
  con la captura de la última prueba de humo en vez de una llamada en directo.
