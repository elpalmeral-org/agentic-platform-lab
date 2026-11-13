# ADR 0026 · CI obligatorio de `platform-harness`: `apm-cli` por pip, un único check `validate-ok`

- **Estado:** Aceptada · 2026-11-13 · cierra F4.1h (F4.1)

## Contexto

Los PR #1-#9 de `platform-harness` (F4.1a-g) se fusionaron sin ningún check automático: las
validaciones (`apm install --dry-run`, `apm compile --dry-run`, `opa test`, `pytest`) se ejecutaron
a mano antes de cada *merge*. El propio repo del harness no tenía el mismo nivel de puerta que exige
a los repos que lo consumen (`harness-ok`, ADR 0023).

Dos huecos de entorno, no de diseño:
- `apm` solo estaba documentado como `brew install apm` (paso 08.8), que no es práctico en un runner
  Linux de GitHub Actions (sin Homebrew preinstalado en `ubuntu-latest`).
- El repo no tenía ningún fichero de dependencias Python: `tests/test_block_secrets.py` dependía de
  tener `pytest` puesto a mano en el Mac de Pablo.

## Decisión

1. **`apm-cli` en CI se instala por `pip`/`pipx`, no por `brew`.** El paquete `apm-cli` en PyPI
   publica el mismo binario `apm` que la fórmula de Homebrew, con las mismas versiones (`0.35.0`
   confirmado: mismo `apm --version`). Evita depender de un runner macOS (más caro, más lento de
   arrancar) solo para tener Homebrew. `brew install apm` sigue siendo la vía documentada para el
   Mac de Pablo (paridad con Brewfile); pip es solo para el runner.
2. **Entorno Python propio del repo:** `pyproject.toml` (grupo `dev` con `pytest`) + `uv.lock`
   versionado. `tests/` se ejecuta con `uv run pytest`, igual que `apps/backend` en `meridian-orders`
   — mismo patrón, misma herramienta (`uv`), en todo el laboratorio.
3. **Tres jobs independientes + un agregado**, mismo patrón que `ci-ok` en `meridian-orders`
   (`.github/workflows/ci.yml`): `apm` (install + compile en seco), `opa` (`opa test -v policy/opa`),
   `pytest` (`uv run pytest tests`), y `validate-ok` (`if: always()`, exige que los tres hayan sido
   `success` o `skipped`). El ruleset de `main` solo necesita apuntar a `validate-ok`: añadir un job
   nuevo no obliga a tocar el ruleset.
4. **Sin runners ARC ni motor A en este CI** (ya decidido en la [ADR 0025](0025-dos-motores-un-harness.md)
   §3): solo puertas deterministas sobre el propio repo del harness, nada de agentes.
5. **Acciones fijadas por SHA**, con el tag como comentario — mismo criterio que `meridian-orders`
   (`actions/checkout`, `astral-sh/setup-uv` reutilizan el mismo SHA ya usado allí;
   `open-policy-agent/setup-opa@v2.2.0` se fija nuevo, SHA resuelto vía `gh api
   repos/open-policy-agent/setup-opa/git/refs/tags/v2.2.0`).
6. **`validate-ok` pasa a obligatorio** en el ruleset `main` de `platform-harness`
   (`required_status_checks`, `strict_required_status_checks_policy: true`).

## Consecuencias

- ✅ El harness se exige a sí mismo la misma disciplina que exige a los repos que lo consumen.
- ✅ Nadie puede fusionar en `platform-harness` sin que `opa test` y `pytest` estén en verde: hasta
  ahora dependía de que quien fusionara se acordara de correrlos a mano.
- ✅ El entorno Python de `tests/` queda fijado y reproducible (`uv.lock`), no solo "instalado en el
  Mac de Pablo".
- ⚠️ Dos vías para instalar `apm` (brew en local, pip en CI): si divergen de versión, el *dry-run* de
  CI puede no coincidir exactamente con el de un desarrollador. Mitigado fijando `0.35.0` en los dos
  sitios (ya lo exigía el paso 08.8 para brew).
- ⚠️ `apm install --dry-run` en CI necesita salir a GitHub a leer la política de la org
  (`elpalmeral-org/.github`): usa el `GITHUB_TOKEN` por defecto del *workflow*, de solo lectura y sin
  secretos de 1Password de por medio.
