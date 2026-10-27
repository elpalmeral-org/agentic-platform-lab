# ADR 0012 · Promoción entre entornos por PR en `platform-gitops`

- **Estado:** Aceptada · 2026-10-25

## Contexto

Hay que llevar una imagen de dev a staging y a prod. Opciones valoradas: PR en el repo GitOps,
Kargo (promoción con UI de etapas, ~500 MiB) y Argo CD Image Updater (actualización automática).

## Decisión

El CI de `meridian-orders` **no despliega**: abre PR en `platform-gitops` que cambian el *digest*
de la imagen en el *overlay* del entorno. Argo CD hace el resto.

```mermaid
sequenceDiagram
    participant APP as meridian-orders (CI)
    participant BOT as GitHub App
    participant OPS as platform-gitops
    participant H as Humano
    participant ARGO as Argo CD
    APP->>APP: build · test · SBOM · cosign → GHCR
    APP->>BOT: token de 1 h (solo platform-gitops)
    BOT->>OPS: PR "dev: sha-abc123" + merge automático
    OPS->>ARGO: sincroniza meridian-dev
    APP->>BOT: release vX.Y.Z
    BOT->>OPS: PR "staging: X.Y.Z"
    H->>OPS: 🧑‍⚖️ aprueba y fusiona
    OPS->>ARGO: sincroniza meridian-staging
    H->>APP: promote prod (entorno con revisor obligatorio)
    BOT->>OPS: PR "prod: X.Y.Z"
    H->>OPS: 🧑‍⚖️ aprueba y fusiona
    OPS->>ARGO: sincroniza meridian-prod
```

## Consecuencias

- ✅ Cero componentes nuevos; cada promoción es un PR con autor, revisor y diff.
- ✅ *Build once*: staging y prod usan **el mismo digest** que se probó en dev.
- ✅ Rollback = revertir el PR.
- ⚠️ Menos vistoso que Kargo en una demo; se puede añadir más adelante sin cambiar este modelo.
