# F3.5b · Ficha del servicio para el acto 1 (docs/demo/ficha-acto-1.md).
# Diseñada en la UI de Port e importada (ADR 0017: la UI para explorar, lo que se queda a código).
# Los widgets viven en pages/service-entity.json tal como los devuelve la API de Port: para
# cambiar la ficha, se edita en la UI, se exporta y se abre un PR (o se edita el JSON directamente).
#
# port_page es BETA en el proveedor: requiere PORT_BETA_FEATURES_ENABLED=true (también en CI).
resource "port_page" "service_entity" {
  identifier = "serviceEntity"
  type       = "entity"
  blueprint  = "service"
  title      = "Service"
  icon       = "Microservice"
  widgets    = [for w in jsondecode(file("${path.module}/pages/service-entity.json")) : jsonencode(w)]
}
