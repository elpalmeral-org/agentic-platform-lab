# ADR 0028 · Excepción visible para la adopción inicial del harness: etiqueta `harness-adopt`

- **Estado:** Aceptada · 2026-11-13 · afina la [ADR 0023](0023-apm-distribucion-harness-ok.md) (regla «el PR cambia ficheros del harness»)

## Contexto

Al implementar F4.3 (`meridian-orders` consume el harness por primera vez) contra la política real
de `pr_gates.rego`, el PR que añade `apm.yml` + los ficheros generados (`AGENTS.md`, `.claude/`,
`.github/instructions/`…) **lo bloquea la propia política**: la única vía para tocar rutas del
harness es `harness_upgrade_pr` (autor `elpalmeral-platform-bot[bot]` + etiqueta `harness-upgrade`),
pensada para cuando el bot abre un PR que **actualiza** una versión ya instalada. La primera
adopción no tiene una versión previa de la que «actualizar»: no hay PR de bot posible todavía,
porque antes de este PR el repo no tiene ni `apm.lock.yaml` ni GitHub App instalada con ese fin.

Alternativa descartada: instalar ya la GitHub App `elpalmeral-platform-bot` ([ADR 0014](0014-github-app-platform-bot.md))
en `meridian-orders` y hacer que abra ella este primer PR. Se descarta **por ahora**: amplía el
alcance de una identidad automatizada a un repo de producto nuevo, algo que la propia ADR 0014 marca
como un cambio que "obliga a reaprobar la instalación" — más superficie de confianza de la
necesaria solo para desbloquear F4.3. Esa decisión queda para cuando se construya de verdad F4.4
(el PR automático de *upgrade*), con la pregunta completa delante: ¿bot o persona con etiqueta?

## Decisión

1. **Nueva regla `harness_adopt_pr`**: un PR con la etiqueta `harness-adopt`, sin exigir autor
   concreto, puede tocar rutas del harness. Mismo patrón que `no-spec-required`: la excepción deja
   un **aviso visible** (`warn`), nunca pasa en silencio.
2. **Es de un solo uso por repo**, por convención, no por control técnico: nada impide poner la
   etiqueta dos veces, pero el aviso («no debería volver a aparecer en este repo») lo hace visible
   en el PR si pasara. F4.4 puede, si hace falta, añadir un control duro (comprobar que
   `apm.lock.yaml` no existía en la base antes de este PR).
3. **F4.4 decide con información completa** si el PR de *upgrade* lo abre el bot (ampliando la
   instalación de `elpalmeral-platform-bot` a los repos de producto) o una persona con esta misma
   etiqueta `harness-adopt`/`harness-upgrade`. No se precompromete aquí.

## Consecuencias

- ✅ F4.3 no queda bloqueado esperando a F4.4 ni obliga a adelantar una decisión de alcance de la
  GitHub App sin pensarla.
- ✅ El patrón de excepción visible (etiqueta + aviso) ya existía (`no-spec-required`): no se
  introduce un mecanismo nuevo, se reutiliza el mismo.
- ⚠️ Mientras F4.4 no exista, cualquier persona puede poner `harness-adopt` en cualquier PR que
  toque ficheros del harness, no solo en la primera adopción. Aceptable: sigue siendo **visible**
  (aviso en el PR) y sigue exigiendo que alguien lo apruebe al fusionar.
