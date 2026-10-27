# release · NUEVO. Una versión de release-please y las imágenes que re-etiqueta (mismo digest).
# Identificador: <servicio>-vX.Y.Z. La escribe publish.yml al re-etiquetar (F3.4).
resource "port_blueprint" "release" {
  identifier            = "release"
  title                 = "Release"
  icon                  = "Git"
  description           = "Versión publicada por release-please; re-etiqueta los digests ya probados en dev"
  force_delete_entities = false

  properties = {
    string_props = {
      version = {
        title = "Versión"
      }
      published_at = {
        title  = "Publicada"
        format = "date-time"
      }
      changelog = {
        title  = "Changelog"
        format = "markdown"
      }
      url = {
        title  = "Release en GitHub"
        format = "url"
      }
    }
  }

  relations = {
    service = {
      title  = "Servicio"
      target = "service"
    }
    builds = {
      title  = "Imágenes"
      target = port_blueprint.build.identifier
      many   = true
    }
  }
}
