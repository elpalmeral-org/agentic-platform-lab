# Adopciones pendientes (ADR 0018). Un bloque import ya aplicado no hace nada: se borra cuando
# el recurso está en el estado. Historial: environment, deployment, workload y la entidad staging
# se importaron en F3.1 (PR #1).

# F3.2 · integración de GitHub Ocean instalada a mano en el paso 07
import {
  to = port_integration.github_ocean
  id = "github-ocean"
}

# F3.5b · ficha del servicio diseñada en la UI (docs/demo/ficha-acto-1.md)
import {
  to = port_page.service_entity
  id = "serviceEntity"
}
