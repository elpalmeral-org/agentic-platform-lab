#!/usr/bin/env bash
# Paso 00 · Mide memoria, ARC de ZFS y fragmentación del host Proxmox.
# Uso (en el host):  sudo bash medir-host.sh [VMID_docker01] | tee /tmp/host-memoria.txt
set -euo pipefail
VMID="${1:-102}"

echo "=== $(hostname) · $(date -Iseconds)"
echo
echo "=== Memoria del host (MiB)"
free -m
echo
echo "=== ARC de ZFS"
awk '$1=="size"{s=$3} $1=="c_max"{m=$3} END{printf "ARC actual: %.1f GiB · tope: %.1f GiB\n", s/1073741824, m/1073741824}' /proc/spl/kstat/zfs/arcstats
echo
echo "=== Memoria asignada a cada VM (MiB)"
qm list | awk 'NR==1 || $3=="running"'
echo
echo "=== Configuración de memoria de la VM ${VMID} (docker01)"
qm config "${VMID}" | grep -E '^(memory|balloon|hugepages|numa|hostpci|args|startup|onboot)' || true
echo
echo "=== Hugepages"
grep -E 'HugePages_(Total|Free)|Hugepagesize' /proc/meminfo
echo
echo "=== Fragmentación (buddyinfo): columnas de la derecha = bloques grandes libres"
cat /proc/buddyinfo
