# build · NUEVO. Una imagen publicada por publish.yml (F3.4), identificada por su digest:
# <servicio>-<componente>-<hex del digest>. Es el eslabón que el CISO quiere ver.
resource "port_blueprint" "build" {
  identifier            = "build"
  title                 = "Build"
  icon                  = "Package"
  description           = "Imagen de contenedor publicada y firmada por el pipeline (una por componente y commit)"
  force_delete_entities = false

  properties = {
    string_props = {
      image = {
        title       = "Imagen"
        description = "repo@sha256:…"
      }
      tag = {
        title = "Tag"
      }
      component = {
        title = "Componente"
        enum  = ["backend", "frontend"]
      }
      commit = {
        title = "Commit"
      }
      built_at = {
        title  = "Construida"
        format = "date-time"
      }
      workflow_run_url = {
        title  = "Ejecución de publish.yml"
        format = "url"
      }
    }
    boolean_props = {
      signed = {
        title       = "Firmada (cosign)"
        description = "Firma keyless de publish.yml en main"
      }
      sbom = {
        title = "SBOM adjunto"
      }
      provenance = {
        title = "Procedencia SLSA"
      }
    }
    number_props = {
      critical_cves = {
        title       = "CVE críticas corregibles"
        description = "Según Grype en el momento de publicar"
      }
    }
  }

  relations = {
    service = {
      title  = "Servicio"
      target = "service"
    }
    pull_request = {
      title  = "PR de código"
      target = "githubPullRequest"
    }
  }
}
