# ADR 0034 · F7: kit de demo — guion con lo que es real hoy, *reset* sin tocar k3s01

- **Estado:** Aceptada · 2026-11-13 · desarrolla [01-arquitectura](../01-arquitectura.md) §6 y el [roadmap](../02-roadmap.md) F7

## Contexto

`docs/demo/README.md` (27-oct) ya fijó el guion de tres actos, el público (CIO/CISO + arquitectura
a partes iguales) y la lista de recursos a construir en F7: `guion.md`, `prompts.md`,
`checklist-previo.md`, `reset.md` + script, `faq-cliente.md`. F7 "se construye cuando el lab
funcione de extremo a extremo" — con F0-F6 cerrados (F6.1 pendiente de una CVE ajena, sin relación
con el guion), toca escribirlos de verdad, revisando contra el estado **real** del lab, no el
diseño de hace tres semanas.

Dos hallazgos reales al revisar ese diseño contra el estado actual:

1. **El mecanismo de *reset* propuesto (volver al *snapshot* `qm snapshot k3s-baseline`) ya no
   sirve.** Ese *snapshot* se tomó en el paso 02 del setup, **antes** de instalar Argo CD, ESO,
   cert-manager, HarnessRouter, ARC y todo lo demás (verificado contra
   `docs/setup/paso-02-k3s.md`: "snapshot... recién instalado, sin addons"). Rebobinarlo borraría
   la plataforma entera, no solo lo que ensucie una demo — exactamente lo que CLAUDE.md §6 prohíbe
   ("`k3s01` con Terraform: nada de... recrear la VM"; aplica igual a un *rollback* de *snapshot*).
2. **El acto 2 tal como está escrito asume que el motor A completa un ciclo autónomo** (petición →
   spec → agente → puertas) igual que el motor B. Verificado contra el estado real tras F4.7: el
   motor A llega hasta `meridian/<rol>` publicado en HarnessRouter y una llamada real a
   `/v1/responses` (probado en la prueba de humo), pero `aidlc-propose.yml`/`aidlc-implement.yml`
   **no** abren todavía un PR con el resultado — eso quedó explícitamente fuera de alcance de F4.7.
   Guionizar un PR automático del motor A en directo describiría algo que no es real.

Estado real verificado antes de escribir el guion (no asumido):
- `meridian-orders`: prod en `0.1.0`, PR #25 `chore(release): 0.2.0` **abierto y sin fusionar**
  (reservado a propósito desde F4.5 para el cierre del acto 3 — comprobado con `gh pr list`).
- `publish.yml` sigue bloqueado para el *frontend* por una CVE de Alpine sin relación (F6.1): un
  demo real que incluya fusionar código nuevo en `main` fallaría hasta que se resuelva en origen.
- El motor B (`/feature`, Claude Code) tiene un ciclo completo real y auditable: F4.5
  (`filtrar-pedidos-por-email`), con un *gate* de seguridad bloqueando de verdad y una enmienda real
  a la spec — el mejor material para el acto 2 en directo.

## Decisión

1. **El acto 2 en directo usa el motor B** (el único con un ciclo petición→PR completo y probado).
   El motor A se **muestra conectado y real** (Port → `dispatch_workflow` → ARC → HarnessRouter →
   `POST /v1/responses` real, con el coste real de la prueba de humo como dato) pero **sin fingir
   un PR automático que no existe**: el guion lo presenta como "mismo harness, mismo contrato,
   motor sin *lock-in*" y nombra explícitamente, si preguntan, que el cierre del ciclo (PR
   autónomo) es el siguiente paso del *roadmap*, no algo ya construido.
2. **`reset.md` + script no tocan la VM de k3s01 ni Argo CD.** Reconciliación de GitOps (la propia
   plataforma) + limpieza de los artefactos que deja una demo: rama/PR de prueba en los repos de
   código, cambios de OpenSpec sin archivar, *harnesses* o *issues* de prueba en HarnessRouter/
   GitHub, entidades de prueba en Port. El estado deseado real (`platform-gitops`) no cambia nunca
   por una demo — solo lo hace el PR #25 el día que de verdad se fusiona.
3. **Los D1-D6 del guion, nombrados explícitamente** (el README de octubre los daba por supuestos):
   - D1 · Crear un servicio desde Port (escenario extra, aplazado: solo hay un servicio).
   - D2 · Pedir una *feature* desde Port, con selector de motor.
   - D3 · Un *gate* bloquea de verdad (el hallazgo real de `security-gate` en F4.5).
   - D4 · Trazabilidad: de la ficha de Port al digest firmado y de vuelta.
   - D5 · Coste por ejecución de agente visible (F6.2, Port).
   - D6 · Aprobaciones humanas del hilo completo (spec, código, prod) — opcional.
4. **`prompts.md` recoge peticiones ya probadas de verdad**, no inventadas: la de F4.5
   (`filtrar-pedidos-por-email`, con su *gate* real) como escenario principal del acto 2, y los dos
   *prompts* mínimos de la prueba de humo de F4.7 (mismo mandato, OpenRouter y Bonsai) como
   evidencia del coste y la latencia reales.
5. **`checklist-previo.md` incluye comprobar el estado real antes de cada demo**, no solo
   «VPN y tokens»: que `publish.yml` pasa para los dos *apps* (la CVE de F6.1 puede seguir
   bloqueándolo), que el PR #25 sigue abierto y sin fusionar, que `harnessrouter-0` está sano, y
   el remanente de la clave de OpenRouter (vía la entidad `openrouter_usage` de Port, F6.2 — sin
   necesidad de leer la clave).

## Consecuencias

- ✅ El guion no describe nada que no se pueda auditar de verdad en directo (principio de
  CLAUDE.md §1: "todo lo que se ve en la demo funciona y se puede auditar").
- ✅ El *reset* es seguro de ejecutar entre demos sin arriesgar la plataforma real.
- ⚠️ El acto 2 queda más modesto para el motor A de lo que el diseño de octubre insinuaba; se
  documenta como una limitación conocida y vigente, no un olvido.
- ⚠️ El acto 3 (fusionar el PR #25 de verdad) es la única acción de la demo que **no es
  repetible sin preparación**: una vez fusionado, hay que cortar una `chore(release)` nueva antes
  de la siguiente demo. `checklist-previo.md` lo marca como paso de preparación, no de la demo en
  sí.
