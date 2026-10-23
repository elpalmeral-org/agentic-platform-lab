# /etc/rancher/k3s/config.yaml · servidor k3s de un nodo (agentic-platform-lab)
# Se renderiza en el Mac con: envsubst < setup/k3s/config.yaml.tpl > /tmp/k3s-config.yaml
node-name: ${K3S_HOST}

# kubeconfig solo legible por root; lo copiamos al Mac en el paso 02
write-kubeconfig-mode: "0600"

# Nombres por los que se accede a la API desde el Mac
tls-san:
  - ${K3S_FQDN}
  - ${K3S_IP}

# Cifrado de Secrets en reposo (se enseña en la demo de seguridad)
secrets-encryption: true

# Se mantienen los componentes de serie de k3s:
#   traefik (ingress), servicelb (expone Traefik en la IP del nodo),
#   local-storage (PV en disco local) y metrics-server (kubectl top).
# Datastore: SQLite (por defecto). Si en el futuro pasamos a 3 nodos, k3s permite
# migrar a etcd embebido reiniciando con cluster-init: true.

# Reserva para el sistema: evita que los pods se coman la memoria del SO
kubelet-arg:
  - "system-reserved=cpu=250m,memory=512Mi"
  - "kube-reserved=cpu=250m,memory=512Mi"
  - "eviction-hard=memory.available<300Mi,nodefs.available<10%"
