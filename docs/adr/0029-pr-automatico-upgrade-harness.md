# ADR 0029 · PR automático de *upgrade* del harness: el bot, por sondeo, no por *dispatch*

- **Estado:** Aceptada · 2026-11-13 · desarrolla la [ADR 0023](0023-apm-distribucion-harness-ok.md) y la [ADR 0028](0028-excepcion-adopcion-inicial-harness.md)

## Contexto

`pr_gates.rego` ya distinguía (desde F4.1f) `harness_upgrade_pr` como «autor
`elpalmeral-platform-bot[bot]` + etiqueta `harness-upgrade`» — pensado para que, cuando se publique
una nueva `harness-vX.Y.Z`, un *workflow* actualice el pin en cada repo consumidor sin que una
persona edite `apm.yml`/`apm.lock.yaml` a mano. Para que el PR lo abra de verdad esa identidad
(y no `github-actions[bot]`, que no coincide con la constante `platform_bot` y caería en el *deny*
genérico), el *workflow* necesita un token de instalación de la GitHub App
(`actions/create-github-app-token`, [ADR 0014](0014-github-app-platform-bot.md)) — y esa App solo
tenía instalado el repo `platform-gitops`. Ampliar su acceso a `meridian-orders` **no se puede
hacer con un token personal de usuario**: solo desde la web de GitHub (org → Settings → GitHub
Apps → Configure), lo hace Pablo.

Dos formas de disparar el *workflow* de *upgrade*:
- **Push:** `platform-harness` manda un `repository_dispatch` a cada consumidor al publicar una
  release. Acopla el repo del harness a la lista de quién lo consume (hoy uno, mañana varios);
  necesitaría mantener esa lista ahí.
- **Pull (elegida):** cada consumidor comprueba por su cuenta, en un *cron*, si hay una release más
  nueva que la que tiene fijada. `platform-harness` no necesita saber quién lo consume.

## Decisión

1. **`.github/workflows/harness-upgrade.yml`** en cada repo consumidor (hoy, `meridian-orders`):
   - Disparo: `schedule` (diario) + `workflow_dispatch` (para probarlo a mano y para la demo).
   - `actions/create-github-app-token` con `PLATFORM_BOT_CLIENT_ID`/`PLATFORM_BOT_PRIVATE_KEY`
     (secretos de org ya existentes, ADR 0014), `owner: elpalmeral-org`,
     `repositories: meridian-orders` — el token nunca se expone, lo consume el *workflow*.
   - `gh api repos/elpalmeral-org/platform-harness/releases/latest` → último tag `harness-vX.Y.Z`.
     Si coincide con `apm.lock.yaml`, no hace nada (sin PR vacío).
   - Si es más nueva: resuelve su SHA, edita el pin en `apm.yml`, `apm install` + `apm compile`,
     commit y PR **con el token de la App** (autor `elpalmeral-platform-bot[bot]`, para que
     `harness_upgrade_pr` se cumpla de verdad) con la etiqueta `harness-upgrade` y el título
     `chore(harness): upgrade X.Y.Z → A.B.C` (el patrón que ya esperaban los tests de
     `pr_gates_test.rego` desde F4.1f).
   - El PR sigue necesitando que una persona lo revise y fusione: `harness-ok` lo valida igual que a
     cualquier otro PR (firma de la release nueva, `apm audit --ci`, OpenSpec).
2. **`minimum_harness_version` en OPA sigue sin automatizar.** Subirlo es una decisión deliberada
   («obligar a todo el parque a actualizar antes de tal fecha»), no algo que un *cron* deba decidir
   por su cuenta.
3. **Alcance de la App ampliado solo a lo necesario:** `meridian-orders`, permisos ya acotados por
   ADR 0014 (contenidos y *pull requests* de ese repo, nada más). Si en el futuro hay más repos
   consumidores, cada uno repite el mismo *workflow* y pide su propia ampliación de alcance.

## Consecuencias

- ✅ `platform-harness` no necesita una lista de quién lo consume: cada consumidor se vigila a sí
  mismo.
- ✅ El PR de *upgrade* es indistinguible, para la política, de como ya se probó en los tests
  (F4.1f): no hizo falta tocar `pr_gates.rego`.
- ⚠️ Con *cron* diario, puede haber hasta 24 h entre una release y su PR de *upgrade* (aceptable:
  no hay SLA de seguridad que lo exija; `workflow_dispatch` cubre la demo donde haga falta
  inmediatez).
- ⚠️ Cada repo consumidor nuevo exige el mismo paso manual de ampliar la instalación de la App:
  **no se automatiza la propia ampliación de permisos** de una identidad automatizada — es,
  deliberadamente, la única parte de este mecanismo que sigue pidiendo una persona.
