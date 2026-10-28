# workload · adoptado de la plantilla (ADR 0018): LO QUE HAY AHORA en un entorno, por componente
# (identificador <servicio>-<componente>-<entorno>, p. ej. meridian-orders-backend-prod).
#   · lo APROBADO (version, approved_digest, build) lo escribe platform-gitops (F3.4)
#   · lo que CORRE (running_image) lo escribe el exportador de Kubernetes (F3.3)
#   · in_sync compara ambos: es la regla de drift del scorecard "Despliegue gobernado"
# Relaciones de plantilla conservadas: environment, service, k8s_workload, argo_application,
# dynatrace_entity, cloud_resource.
resource "port_blueprint" "workload" {
  identifier            = "workload"
  title                 = "Workload"
  icon                  = "Deployment"
  description           = "Un componente de un servicio en un entorno: lo aprobado en GitOps frente a lo que corre"
  force_delete_entities = false

  ownership = {
    type = "Inherited"
    path = "service"
  }

  properties = {
    string_props = {
      version = {
        title       = "Version"
        description = "Versión aprobada en GitOps (newTag del overlay)"
      }
      component = {
        title = "Componente"
        enum  = ["backend", "frontend"]
      }
      approved_digest = {
        title       = "Digest aprobado"
        description = "Digest fijado en el overlay de platform-gitops"
      }
      running_image = {
        title       = "Imagen en ejecución"
        description = "Imagen que informa el clúster (repo:tag@digest)"
      }
      url = {
        title  = "URL"
        format = "url"
      }
    }
  }

  relations = {
    build = {
      title  = "Imagen aprobada"
      target = port_blueprint.build.identifier
    }
  }

  calculation_properties = {
    in_sync = {
      title       = "Corre lo aprobado"
      description = "La imagen en ejecución termina en el digest aprobado (vacío si falta alguno de los dos)"
      type        = "boolean"
      calculation = ".properties as $p | if (($p.approved_digest // \"\") == \"\") or (($p.running_image // \"\") == \"\") then null else ($p.running_image | endswith($p.approved_digest)) end"
    }
  }

  mirror_properties = {
    argoApplication = {
      path  = "argo_application.$identifier"
      title = "Application"
    }
    argo_health_status = {
      path  = "argo_application.healthStatus"
      title = "Argo Health status"
    }
    argo_labels = {
      path  = "argo_application.labels"
      title = "Labels"
    }
    argo_sync_status = {
      path  = "argo_application.syncStatus"
      title = "Argo Sync status"
    }
    dynatrace_entity_name = {
      path  = "dynatrace_entity.$title"
      title = "Dynatrace Entity Name"
    }
    running_replicas = {
      path  = "k8s_workload.availableReplicas"
      title = "Running Replicas"
    }
    wanted_replicas = {
      path  = "k8s_workload.replicas"
      title = "Wanted Replicas"
    }
    workload_health = {
      path  = "k8s_workload.isHealthy"
      title = "Workload Health"
    }
    workload_identifier = {
      path  = "k8s_workload.$identifier"
      title = "Workload identifier"
    }
    signed = {
      path  = "build.signed"
      title = "Firmada"
    }
    critical_cves = {
      path  = "build.critical_cves"
      title = "CVE críticas"
    }
    sbom = {
      path  = "build.sbom"
      title = "SBOM"
    }
    provenance = {
      path  = "build.provenance"
      title = "Procedencia SLSA"
    }
  }
}
