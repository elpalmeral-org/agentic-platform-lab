# Reset · volver al estado limpio entre demos

> **No toca k3s01 ni Argo CD.** El diseño de octubre proponía volver al *snapshot* `qm snapshot
> k3s-baseline` — ese *snapshot* es de **antes** de instalar Argo CD, ESO, HarnessRouter, ARC y
> todo lo demás (ADR 0034): rebobinarlo borraría la plataforma entera, no solo lo que ensucie una
> demo. El estado deseado del clúster (`platform-gitops`) no cambia nunca por una demo.

## Qué ensucia una demo

| Repo/sistema | Qué puede quedar | Se limpia con |
|---|---|---|
| `meridian-orders` | *Issue* `aidlc:claude` abierto (D2) | Cerrarlo a mano, con un comentario |
| `meridian-orders` | `openspec/changes/<cambio>/` sin archivar si la demo no llegó al final | Archivarlo o borrar la carpeta si el PR nunca se fusionó |
| `meridian-orders` | Rama/PR del motor B sin fusionar | Cerrar el PR, borrar la rama |
| HarnessRouter | *Harness* de prueba que no sea uno de los 5 `meridian/<rol>` reales | `DELETE /v1/harnesses/{id}` |
| Port | Entidad de prueba fuera de los blueprints reales (`release`, `harness_status`, `openrouter_usage`, …) | Borrar la entidad desde la UI o MCP |
| ARC | *Pods* efímeros | Nada que hacer: se autolimpian (verificado en F5) |

## Cómo usarlo

`scripts/demo-reset.sh` (en este repo) es **de solo lectura**: lista lo que encuentra y da el
comando exacto para cada cosa — no borra nada por su cuenta. La limpieza real la ejecuta una
persona, a propósito, igual que cualquier otra acción irreversible del lab.

```bash
./scripts/demo-reset.sh
```

Requiere `gh` autenticado y, si se quiere comprobar HarnessRouter también, la clave de la Console
disponible vía `op read -n 'op://agentic-lab/harnessrouter/api_key'`.

## Checklist tras una demo (en menos de 10 min)

- [ ] Cerrar el *issue* `aidlc:claude` que haya creado la demo (D2), con un comentario.
- [ ] Si el motor B llegó a abrir un PR de *spec* o de código sin fusionar: cerrarlo y borrar la
      rama.
- [ ] Si el cambio de OpenSpec de la demo se fusionó de verdad: archivarlo (patrón ya establecido,
      `openspec/changes/archive/<fecha>-<cambio>/`).
- [ ] Si se creó algún *harness* de prueba en HarnessRouter (no uno de los 5 roles reales):
      borrarlo.
- [ ] Confirmar que prod sigue en la versión esperada en la ficha de Port (si se fusionó el PR de
      *release* en una demo, es un hecho real, no hay que "deshacerlo" — solo anotarlo).
- [ ] Relanzar `scripts/demo-reset.sh` una vez más: debe salir limpio.
