# Prueba de humo del paso 02: ingress (Traefik + DNS wildcard) y almacenamiento (local-path).
# Uso:
#   envsubst < setup/k3s/smoke-test.yaml.tpl | kubectl apply -f -
#   ...verificar...
#   kubectl delete namespace smoke-test
apiVersion: v1
kind: Namespace
metadata:
  name: smoke-test
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: whoami
  namespace: smoke-test
spec:
  replicas: 1
  selector:
    matchLabels: { app: whoami }
  template:
    metadata:
      labels: { app: whoami }
    spec:
      containers:
        - name: whoami
          image: traefik/whoami:v1.10.1
          ports:
            - containerPort: 80
          resources:
            requests: { cpu: 10m, memory: 16Mi }
            limits: { memory: 32Mi }
---
apiVersion: v1
kind: Service
metadata:
  name: whoami
  namespace: smoke-test
spec:
  selector: { app: whoami }
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: whoami
  namespace: smoke-test
spec:
  rules:
    - host: whoami.${LAB_SUBDOMAIN}.${LAB_DOMAIN}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: whoami
                port:
                  number: 80
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data
  namespace: smoke-test
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: local-path
  resources:
    requests:
      storage: 100Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: storage-check
  namespace: smoke-test
spec:
  restartPolicy: Never
  containers:
    - name: check
      image: busybox:1.37
      command: ["sh", "-c", "echo ok > /data/probe && cat /data/probe"]
      volumeMounts:
        - name: data
          mountPath: /data
      resources:
        requests: { cpu: 10m, memory: 8Mi }
        limits: { memory: 16Mi }
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: data
