# Paso 01 · VM k3s01 para el agentic-platform-lab.
#
# Se copia TAL CUAL al repo privado homelab-terraform (mismo estilo que docker01):
#   cp setup/proxmox/k3s01.tf ~/git/homelab/homelab-terraform/k3s01.tf
# y los valores se añaden a su terraform.tfvars (ver k3s01.tfvars.example).
#
# Reutiliza las variables default_* ya definidas en homelab-terraform/variables.tf.

################################################################################
# Variables
################################################################################

variable "k3s01_vm_id" {
  description = "ID de la VM k3s01"
  type        = number
  default     = 110
}

variable "k3s01_vm_hostname" {
  description = "Hostname de k3s01"
  type        = string
  default     = "k3s01"
}

variable "k3s01_vm_tags" {
  description = "Etiquetas de k3s01"
  type        = list(string)
  default     = ["k3s", "lab", "terraform"]
}

variable "k3s01_cpu_cores" {
  description = "vCPU de k3s01"
  type        = number
  default     = 6
}

variable "k3s01_memory_dedicated" {
  description = "RAM de k3s01 en MiB"
  type        = number
  default     = 10240
}

variable "k3s01_disk_size" {
  description = "Disco de k3s01 en GB (imágenes + volúmenes local-path)"
  type        = number
  default     = 80
}

variable "k3s01_ipv4_address" {
  description = "IP/máscara de k3s01 (fuera del rango DHCP)"
  type        = string
}

variable "k3s01_startup_order" {
  description = "Orden de arranque: mayor que el de docker01, que sirve el DNS"
  type        = number
  default     = 20
}

variable "k3s01_template_vm_id" {
  description = "Plantilla de la que se clona k3s01: Debian 13 cloud-init (homelab-terraform/templates/debian13)"
  type        = number
  default     = 9013
}

variable "lab_subdomain" {
  description = "Subdominio del lab; *.<lab_subdomain>.<dominio> apunta a k3s01"
  type        = string
  default     = "apl"
}

################################################################################
# VM
################################################################################

resource "proxmox_virtual_environment_vm" "k3s01" {
  name        = var.k3s01_vm_hostname
  description = "k3s de un nodo · agentic-platform-lab · gestionada con Terraform"
  node_name   = var.default_node
  vm_id       = var.k3s01_vm_id
  tags        = var.k3s01_vm_tags
  on_boot     = true

  # Arranca después de docker01 (DNS) y da margen a que el DNS responda
  startup {
    order    = var.k3s01_startup_order
    up_delay = 60
  }

  agent {
    enabled = var.default_agent_enabled
    timeout = "15m"
  }

  cpu {
    cores   = var.k3s01_cpu_cores
    sockets = 1
    type    = var.default_cpu_type
    numa    = false
  }

  # Sin balloon: Kubernetes calcula su capacidad con la RAM que ve
  memory {
    dedicated = var.k3s01_memory_dedicated
  }

  network_device {
    bridge = var.default_network_bridge
    model  = var.default_network_model
    mtu    = var.default_mtu_value
  }

  operating_system {
    type = var.default_os_type
  }

  # Igual que la plantilla: los kernels cloud de Debian sacan la consola por ttyS0
  serial_device {
    device = "socket"
  }

  vga {
    type = "serial0"
  }

  disk {
    replicate    = var.default_replicate_value
    datastore_id = var.default_disk_datastore_id
    file_format  = var.default_disk_file_format
    interface    = var.default_disk_interface
    discard      = var.default_disk_discard
    iothread     = var.default_disk_iothread
    size         = var.k3s01_disk_size
  }

  initialization {
    datastore_id = var.default_disk_datastore_id

    dns {
      servers = var.default_dns_servers # incluye resolvers de respaldo además de Technitium
      domain  = var.default_dns_domain
    }

    ip_config {
      ipv4 {
        address = var.k3s01_ipv4_address
        gateway = var.default_ipv4_gateway
      }
    }

    user_account {
      username = var.default_cloud_init_user
      keys     = var.default_cloud_init_ssh_keys
    }
  }

  # Plantilla propia (9013), NO default_clone_vm_id: cambiar esa variable
  # haría que Terraform quisiera recrear docker01 y nas01.
  clone {
    vm_id = var.k3s01_template_vm_id
    full  = var.default_clone_full
  }
}

################################################################################
# DNS (Technitium)
################################################################################

resource "technitium_dns_zone_record" "k3s01_a" {
  zone       = var.default_dns_domain
  domain     = "${var.k3s01_vm_hostname}.${var.default_dns_domain}"
  type       = "A"
  ttl        = var.default_dns_record_ttl
  ip_address = split("/", var.k3s01_ipv4_address)[0]
  comments   = var.default_dns_record_comments

  depends_on = [proxmox_virtual_environment_vm.k3s01]
}

# Wildcard del lab: argocd.<sub>.<dominio>, uhp.<sub>.<dominio>, orders-dev.<sub>.<dominio>…
resource "technitium_dns_zone_record" "lab_wildcard_a" {
  zone       = var.default_dns_domain
  domain     = "*.${var.lab_subdomain}.${var.default_dns_domain}"
  type       = "A"
  ttl        = var.default_dns_record_ttl
  ip_address = split("/", var.k3s01_ipv4_address)[0]
  comments   = "agentic-platform-lab · ${var.default_dns_record_comments}"

  depends_on = [proxmox_virtual_environment_vm.k3s01]
}

################################################################################
# Outputs
################################################################################

output "k3s01" {
  description = "Información de la VM k3s01"
  value = {
    vm_id = proxmox_virtual_environment_vm.k3s01.vm_id
    name  = proxmox_virtual_environment_vm.k3s01.name
    ipv4  = split("/", var.k3s01_ipv4_address)[0]
    lab   = "*.${var.lab_subdomain}.${var.default_dns_domain}"
  }
}
