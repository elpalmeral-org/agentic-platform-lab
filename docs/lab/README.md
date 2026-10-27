# ② Lab · componentes de la plataforma

> Esta sección describe la plataforma **en marcha**. Se rellena fase a fase; cada componente tendrá
> su página con: qué hace, cómo se despliega (siempre desde `platform-gitops`), cómo se opera y
> cómo se usa en la demo.

```mermaid
flowchart TB
    subgraph F1["F1 · base"]
        ARGO["argocd.md"]
        SEC["secretos.md"]
        ING["ingress-tls.md"]
        POL["politicas.md"]
    end
    subgraph F2["F2 · app"]
        APP["meridian-orders.md"]
        CICD["ci-cd.md"]
    end
    subgraph F3["F3 · IDP"]
        PORT["port.md"]
    end
    subgraph F4["F4 · harness"]
        HAR["harness.md"]
        SDD["openspec.md"]
    end
    subgraph F5["F5 · agentes"]
        UHP["uhp-harnessrouter.md"]
        ARC["arc-runners.md"]
        AIDLC["aidlc.md"]
    end
    subgraph F6["F6 · obs"]
        OBS["observabilidad.md"]
    end
    F1 --> F2 --> F3
    F2 --> F4 --> F5
    F3 --> F5 --> F6
```

| Componente | Página | Fase | Estado |
|---|---|---|---|
| Argo CD y *app-of-apps* | [`argocd.md`](argocd.md) | F1 | ✅ |
| Secretos (ESO + 1Password) | [`secretos.md`](secretos.md) | F1 | ✅ |
| Ingress y TLS (cert-manager + LE DNS-01) | [`ingress-tls.md`](ingress-tls.md) | F1 | ✅ |
| Políticas de admisión (Kyverno) y cuotas | `politicas.md` | F1 | ⏸️ pendiente (tras F2) |
| Meridian Orders | [`meridian-orders.md`](meridian-orders.md) | F2 | ✅ dev · staging · prod |
| CI/CD y promoción | [`ci-cd.md`](ci-cd.md) | F2 | ✅ |
| Port.io | [`port.md`](port.md) | F3 | 🟡 diseñado |
| Harness corporativo | `harness.md` | F4 | ⚪ |
| OpenSpec / SDD | `openspec.md` | F4 | ⚪ |
| HarnessRouter (UHP) | `uhp-harnessrouter.md` | F5 | ⚪ |
| Runners ARC | `arc-runners.md` | F5 | ⚪ |
| Flujo AIDLC | `aidlc.md` | F5 | ⚪ |
| Observabilidad y coste | `observabilidad.md` | F6 | ⚪ |
