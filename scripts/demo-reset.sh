#!/usr/bin/env bash
# Reset entre demos (F7, ADR 0034): de SOLO LECTURA. Lista lo que una demo puede haber dejado
# sucio y da el comando exacto para cada cosa; no borra nada por su cuenta — la limpieza real la
# ejecuta una persona, a propósito, igual que cualquier otra acción irreversible del lab (CLAUDE.md
# §6). NO toca k3s01 ni Argo CD: ver docs/demo/reset.md.
#
#   scripts/demo-reset.sh
#
# Requisitos: gh autenticado. Para comprobar HarnessRouter también, además:
#   op (1Password CLI) con sesión activa.
# Compatible con el bash 3.2 de macOS (sin mapfile).
set -euo pipefail

ORG="elpalmeral-org"
MERIDIAN="$ORG/meridian-orders"

echo "== 1 · issues aidlc:claude abiertos en $MERIDIAN =="
issues="$(gh issue list --repo "$MERIDIAN" --label aidlc:claude --state open --json number,title,url 2>/dev/null || echo '[]')"
count="$(echo "$issues" | jq 'length')"
if [ "$count" = "0" ]; then
  echo "  (ninguno)"
else
  echo "$issues" | jq -r '.[] | "  #\(.number) \(.title) — \(.url)"'
  echo "  comando: gh issue close <número> --repo $MERIDIAN --comment \"<motivo>\""
fi

echo
echo "== 2 · PR abiertos en $MERIDIAN con rama feat/demo-* o fix/demo-* =="
prs="$(gh pr list --repo "$MERIDIAN" --state open --json number,title,headRefName,url 2>/dev/null || echo '[]')"
demo_prs="$(echo "$prs" | jq '[.[] | select(.headRefName | test("^(feat|fix)/demo-"))]')"
count="$(echo "$demo_prs" | jq 'length')"
if [ "$count" = "0" ]; then
  echo "  (ninguno)"
else
  echo "$demo_prs" | jq -r '.[] | "  #\(.number) \(.title) — \(.url)"'
  echo "  comando: gh pr close <número> --repo $MERIDIAN --delete-branch"
fi

echo
echo "== 3 · openspec/changes/ sin archivar en $MERIDIAN (rama main) =="
changes="$(gh api "repos/$MERIDIAN/contents/openspec/changes?ref=main" --jq '[.[] | select(.type == "dir" and .name != "archive") | .name]' 2>/dev/null || echo '[]')"
count="$(echo "$changes" | jq 'length')"
if [ "$count" = "0" ]; then
  echo "  (ninguno)"
else
  echo "$changes" | jq -r '.[] | "  openspec/changes/\(.)"'
  echo "  si el PR de código ya se fusionó: archivar (openspec/changes/archive/<fecha>-<cambio>/)."
  echo "  si el PR nunca se fusionó: borrar la carpeta en una rama y PR normal."
fi

echo
echo "== 4 · harnesses en HarnessRouter que no son uno de los 5 roles reales =="
if command -v op > /dev/null 2>&1 && op read -n 'op://agentic-lab/harnessrouter/api_key' > /tmp/demo-reset-key 2>/dev/null; then
  key="$(cat /tmp/demo-reset-key)"
  rm -f /tmp/demo-reset-key
  status="$(curl -s -o /tmp/demo-reset-harnesses.json -w '%{http_code}' --max-time 15 \
    -H "Authorization: Bearer $key" \
    https://uhp.apl.elpalmeral.es/api/harness/v1/harnesses 2>/dev/null || echo 000)"
  if [ "$status" = "200" ]; then
    extra="$(jq -r '.harnesses[] | select(.name | test("^meridian/") | not) | "  \(.id) \(.name)"' /tmp/demo-reset-harnesses.json)"
    if [ -z "$extra" ]; then
      echo "  (ninguno)"
    else
      echo "$extra"
      echo "  comando: curl -X DELETE -H \"Authorization: Bearer \$(op read -n 'op://agentic-lab/harnessrouter/api_key')\" https://uhp.apl.elpalmeral.es/api/harness/v1/harnesses/<id>"
    fi
  else
    echo "  (no se pudo comprobar: HTTP $status — ¿harnessrouter-0 está sano?)"
  fi
  rm -f /tmp/demo-reset-harnesses.json
else
  echo "  (omitido: op sin sesión activa o sin el item agentic-lab/harnessrouter)"
fi

echo
echo "== Resumen =="
echo "Ninguna de estas acciones se ha ejecutado. Repasar docs/demo/reset.md y actuar a mano."
