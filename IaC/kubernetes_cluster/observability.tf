resource "helm_release" "kube-prometheus-stack" {
  name = "kube-prometheus-stack"
  namespace = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart = "kube-prometheus-stack"
  version = "62.2.1"
  create_namespace = true
  timeout = 600

  set {
    name  = "grafana.enabled"
    value = "false"
  }

  set {
    name  = "prometheus.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "prometheus.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"             
  }

  set {
    name  = "prometheus.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }

  set {
    name  = "prometheus-node-exporter.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key"
    value = "eks.amazonaws.com/compute-type"
  }

  set {
    name  = "prometheus-node-exporter.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator"
    value = "NotIn"
  }

  set {
    name  = "prometheus-node-exporter.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0]"
    value = "fargate"
  }

  depends_on = [ module.eks, helm_release.aws-load-balancer-controller ]
}