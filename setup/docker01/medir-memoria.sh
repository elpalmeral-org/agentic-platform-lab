#!/usr/bin/env bash
# Paso 00 · Mide el consumo real de memoria de docker01.
# Uso (en docker01):  sudo bash medir-memoria.sh | tee /tmp/docker01-memoria.txt
set -euo pipefail

echo "=== $(hostname) · $(date -Iseconds)"
echo
echo "=== Memoria (MiB)"
free -m
echo
awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "Usada real (total - available): %.1f GiB de %.1f GiB\n", (t-a)/1048576, t/1048576}' /proc/meminfo
echo
echo "=== Presión de memoria (PSI): some/full avg300 deberían ser ~0"
cat /proc/pressure/memory
echo
echo "=== Swap"
swapon --show || true
echo
echo "=== Top 15 contenedores por memoria"
docker stats --no-stream --format '{{.MemUsage}}\t{{.Name}}' | sort -h -r | head -15
echo
echo "=== Contenedores con límite de memoria explícito"
docker ps -q | xargs -r docker inspect --format '{{.Name}} {{.HostConfig.Memory}}' | awk '$2>0{printf "%s %.1f GiB\n",$1,$2/1073741824}'
echo
echo "=== Modelos de Ollama cargados (si existe el contenedor)"
docker exec ollama ollama ps 2>/dev/null || echo "(sin contenedor 'ollama' o sin modelos cargados)"
echo
echo "=== OOM recientes en el kernel (30 días)"
journalctl -k --since "30 days ago" --no-pager 2>/dev/null | grep -iE "out of memory|oom-kill" | tail -10 || echo "(ninguno)"
