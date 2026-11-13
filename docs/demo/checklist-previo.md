# Checklist previo · 30 min antes de la demo

> No es solo "¿tengo VPN y tokens?" — es confirmar el **estado real** del lab contra lo que el
> guion va a prometer. Cada paso dice qué mirar y qué hacer si falla.

## 1 · Acceso

- [ ] VPN WireGuard activa (Mac → LAN del homelab).
- [ ] 1Password desbloqueado (agente SSH; si se bloquea a mitad de una demo, no hay *fallback*:
      desbloquear y reintentar).
- [ ] `gh auth status` en verde para `elpalmeral-org`.
- [ ] Sesión de Claude Code activa con la suscripción (motor B).

## 2 · Estado real de `meridian-orders`

- [ ] `gh pr list --repo elpalmeral-org/meridian-orders --state open` → el PR `chore(release):
      0.2.0` **sigue abierto** (si no, cortar una `chore(release)` nueva antes de prometer el acto
      3 en directo — se abre sola tras el siguiente *merge* a `main`, pero necesita tiempo).
- [ ] `gh run list --workflow publish.yml --branch main --limit 1`: el último *run* en `main`
      **pasa para los dos *apps*** (`backend` y `frontend`). Si el *frontend* sigue fallando por
      la CVE de F6.1 (`libxslt`/`libexpat`, Alpine): no prometer fusionar el PR de *release* en
      directo — usar el `faq-cliente.md` si preguntan, no intentarlo a ciegas.
- [ ] Prod sigue en `0.1.0` en la ficha de Port (si ya está en `0.2.0`, el acto 3 necesita un
      cambio nuevo preparado, no el PR #25).

## 3 · HarnessRouter y los dos motores

- [ ] `kubectl get pods -n harnessrouter` → `Running`, sin reinicios recientes.
- [ ] `curl -sw '%{http_code}' .../api/harness/v1/harnesses` (con la clave) → `200`, y los 5
      `meridian/<rol>` siguen en la lista.
- [ ] `kubectl get pods -n arc-runners` (o el *listener* de ARC) → sano; un `workflow_dispatch` de
      `arc-smoke-test.yml` si hay dudas.
- [ ] `curl http://192.168.0.6:11435/metrics | grep requests_processing` → `0` (Bonsai libre,
      no en uso por Hermes) antes de prometer la demo en vivo del motor abierto.

## 4 · Coste y presupuesto

- [ ] Entidad `openrouter_usage` en Port (vía MCP o la UI): remanente de la clave muy por encima
      de lo que puede gastar la demo (cada llamada de la prueba de humo costó ~0,007 $).
- [ ] Si el remanente es bajo: avisar antes de la demo, no a mitad — el acto 2 puede hacerse solo
      con el motor B si hace falta ahorrar presupuesto.

## 5 · Limpieza previa

- [ ] `openspec/changes/` en `meridian-orders` sin cambios de una demo anterior sin archivar.
- [ ] Sin ramas `feat/demo-*`/`fix/demo-*` colgando en los repos que se van a usar en directo.
- [ ] Si hubo una demo antes y no se corrió `reset.sh`: correrlo ahora (`reset.md`).

## 6 · Pantallas

- [ ] Ficha de `meridian-orders` en Port, pestaña de entorno `prod`, ya abierta.
- [ ] Terminal con Claude Code listo (motor B) y otra con `curl`/`op` a mano (motor abierto).
- [ ] `prompts.md` y `guion.md` abiertos, no solo en la cabeza.
