# F3.1a · Adopción de los blueprints de la plantilla que vamos a ampliar (ADR 0018).
# Con "terraform plan -generate-config-out=generated.tf" Terraform escribe su código tal como
# están hoy en Port; después se ordena por ficheros y estos bloques se pueden borrar.
#
# Las agregaciones (DORA, etc.) se gestionan con un recurso aparte: port_aggregation_properties.

import {
  to = port_blueprint.environment
  id = "environment"
}

import {
  to = port_blueprint.deployment
  id = "deployment"
}

import {
  to = port_blueprint.workload
  id = "workload"
}

# El entorno staging de la plantilla se conserva (dev y prod se crean nuevos; test y production se borran)
import {
  to = port_entity.staging
  id = "environment:staging" # <blueprint>:<entidad>
}
