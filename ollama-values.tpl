replicaCount: 4

ollama:
  gpu:
    enabled: true
  models:
    - llama3.1

service:
  type: LoadBalancer
  port: ${port}
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-resource-group: "${resource_group}"
    service.beta.kubernetes.io/azure-load-balancer-ipv4: "${ip_address}"
    service.beta.kubernetes.io/azure-dns-label-name: "${dns_label_name}"

tolerations:
  - key: nvidia.com/gpu
    operator: Exists
    effect: NoSchedule