# ADR 0003 · k3s de un nodo en VM nueva, recortando docker01

- **Estado:** Aceptada · 2026-10-23

## Contexto

El host Proxmox (62,7 GiB, 24 hilos) está a ~51 GiB de RAM usada. docker01 tiene 32 GiB que
quedan **fijados en memoria física** porque usa VFIO (GPU) y virtiofs (`memory-backend-memfd`).
Hace falta hueco para una VM k3s sin comprar hardware todavía.

Opciones valoradas:

| Opción | Pros | Contras |
|---|---|---|
| 1 nodo + ampliar RAM | Holgura | Espera a la compra |
| 1 nodo pequeño (8 GiB) | Inmediato | Muy justo para HarnessRouter + runners |
| 3 nodos | Realismo (HA, drenado) | Necesita RAM que no hay |
| **Recortar docker01** | Inmediato, sin coste | Hay que medir para no afectar a los 37 contenedores |

## Decisión

- Recortar docker01 de 32 a **24 GiB**, tras medir su consumo real (paso 00).
- Nueva VM **k3s01**: 6 vCPU, 10 GiB, 80 GB en `fastpool`, sin GPU, gestionada con Terraform
  (`bpg/proxmox`) en `homelab-terraform`.
- k3s de **un nodo**, con Traefik, ServiceLB y local-path que trae de serie.
- Entornos `dev/staging/prod` como **namespaces**.

## Consecuencias

- ✅ Kubernetes real sin coste.
- ✅ La reducción de docker01 también alivia la fragmentación de memoria detectada en la auditoría
  (arranques de docker01 que fallaban al fijar la RAM).
- ⚠️ Sin HA: si cae k3s01, cae el lab (aceptable: no es producción).
- ⚠️ k3s01 depende del DNS de docker01 (Technitium): k3s01 arranca después y tiene DNS de respaldo.
- 🔁 Revisable cuando se amplíe la RAM (pasar a 3 nodos para demos de resiliencia).
