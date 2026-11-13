# ADR 0027 · Release firmada de `platform-harness`: bundle `claude-plugin`, firma keyless con la identidad del workflow

- **Estado:** Aceptada · 2026-11-13 · desarrolla la [ADR 0023](0023-apm-distribucion-harness-ok.md) §«cosign keyless el bundle»

## Contexto

La ADR 0023 fijó que cada release firma «el bundle (`apm pack`) y un manifiesto que liga el tag con
su commit», sin fijar el formato del bundle ni cómo se hace la firma *keyless*. Dos cosas que
aclarar antes de automatizarlo:

1. `apm pack` tiene tres formatos (`agent-plugin`, `claude-plugin`, `apm`). Probado en local:
   - `--format agent-plugin` (el que la [ADR 0022](0022-harness-repo-propio-formatos-abiertos.md)
     señala como «formato de paquete de UHP») **rechaza empaquetar** este repo: solo admite
     `plugin.json` + `skills/` + `mcp.json`, y descartaría los mandatos de agente (`.apm/agents/`),
     el hook `block-secrets` y las instrucciones. `apm pack` lo bloquea con un error explícito en
     vez de empaquetar a medias.
   - `--format apm` («legacy APM bundle layout») empaqueta lo ya **desplegado** (`AGENTS.md`,
     `.claude/`…), no la fuente: con nada desplegado en este repo (aquí solo vive la fuente, nunca
     lo generado — ver README) produce un bundle vacío.
   - `--format claude-plugin` (el valor por defecto sin `--format`) es el único que empaqueta los
     17 ficheros reales de la fuente: los 5 mandatos, `/feature`, las 3 instrucciones, la skill
     `corporate-grounding` con su corpus, `hooks.json` y `.mcp.json` (con los secretos del MCP de
     Port ya sustituidos por referencia a variable de entorno, nunca en claro).
2. `cosign sign-blob --keyless` sin más contexto abre un flujo OIDC **interactivo** (navegador) y
   firma con la identidad personal de quien lo ejecuta. Esa identidad (el correo) queda publicada
   **para siempre** en el log de transparencia público de Rekor (Sigstore). No es aceptable para el
   correo personal de Pablo, y tampoco aporta nada: lo que un consumidor quiere verificar no es
   «Pablo firmó esto», sino «esto lo construyó el pipeline de `platform-harness`, en este commit,
   sin intervención manual».

## Decisión

1. **Formato del bundle: `claude-plugin` (el valor por defecto de `apm pack`, sin `--format`),
   como `.zip`** (`--archive --archive-format zip`). Es el único formato probado que conserva el
   harness completo. El nombre del formato no implica que el bundle sea solo para Claude Code: es
   el contenedor que mejor conserva agentes/hooks/instrucciones de los tres disponibles en esta
   versión de `apm` (0.35.0); si una versión futura de Agent Plugins cubre agentes y hooks, se
   revisita.
2. **La firma se hace en CI, no en local**, con la identidad OIDC del propio *workflow* de GitHub
   Actions (`id-token: write`, sin flags de identidad adicionales): el certificado de Sigstore
   queda con el *subject* `https://github.com/elpalmeral-org/platform-harness/.github/workflows/release.yml@refs/tags/<tag>`,
   no un correo personal. Dispara con `on: push: tags: harness-v*`; solo un admin puede crear ese
   tag (ruleset `tags-harness`, ya existente desde el paso 08).
3. **Manifiesto** `manifest.json`: `{tag, commit, digest (sha256 del .zip), format, archive,
   signature}`. Se publica junto al `.zip` y el *bundle* de firma (`<archivo>.sigstore.json`: firma
   + certificado + prueba del log de transparencia, formato moderno de `cosign sign-blob --bundle`;
   los flags separados `--output-signature`/`--output-certificate` están obsoletos) como *assets*
   de una **GitHub Release**, inmutable.
4. **Puerta previa a empaquetar:** el workflow repite `apm install/compile --dry-run`, `opa test` y
   `pytest` (los mismos tres de `validate.yml`, [ADR 0026](0026-ci-obligatorio-platform-harness.md))
   y comprueba que el tag coincide con la `version:` de `apm.yml` antes de firmar nada. No depende
   de que el *merge* a `main` ya haya pasado por `validate-ok`: un tag se puede crear sobre cualquier
   commit, así que la release repite las comprobaciones por su cuenta.
5. **Contrato de verificación para quien consuma el harness** (lo implementa F4.3, `harness-ok`):
   ```
   cosign verify-blob --bundle <archivo>.sigstore.json \
     --certificate-identity-regexp 'https://github.com/elpalmeral-org/platform-harness/.github/workflows/release.yml@.*' \
     --certificate-oidc-issuer https://token.actions.githubusercontent.com \
     <archivo>
   ```
   El check `harness-signature` de `pr_gates.rego` (ya existente) pasa a `success` cuando esta
   verificación pasa para la versión fijada en `apm.lock.yaml`.

## Consecuencias

- ✅ Nadie firma con su identidad personal; el log público de Rekor solo expone «este repo, este
  workflow, este tag», que es exactamente lo que un cliente quiere poder auditar en el acto 1/3 de
  la demo.
- ✅ El bundle firmado contiene el harness completo (agentes, hooks, instrucciones, skills, MCP),
  no solo la parte que cabe en Agent Plugins 1.0.
- ⚠️ Mientras Agent Plugins 1.0 no cubra agentes/hooks, el bundle firmado no es literalmente «lo que
  recibe UHP» (eso lo lee `harness-sync`, F4.7, directo de la fuente en el tag, no de este `.zip`):
  la firma certifica el commit, no un artefacto que UHP consuma byte a byte.
- ⚠️ Una release repite todo `validate.yml` dentro del propio `release.yml`: algo de duplicación
  deliberada, para que un tag nunca produzca una release sin pasar las mismas puertas, incluso si
  alguien crea el tag sobre un commit que no pasó por un PR.
