
# resource "helm_release" "kube-prometheus-stack" {
#   name = "kube-prometheus-stack"
#   namespace = "monitoring"
#   repository = "https://prometheus-community.github.io/helm-charts"
#   chart = "kube-prometheus-stack"
#   version = "62.2.1"
#   create_namespace = true
#   set {
#     name  = "grafana.adminPassword"
#     # need to change with secure value
#     value = "password"
#   }

#   set {
#     name  = "grafana.ingress.enabled"
#     value = "true"
#   }

#   set {
#     name  = "grafana.ingress.ingressClassName"
#     value = "nginx"
#   }

#   set {
#     name  = "grafana.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
#     value = "internet-facing"
#   }

#   set {
#     name  = "grafana.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"
#     value = "ip"
#   }
#   set {
#     name  = "grafana.ingress.paths[0]"
#     value = "/monitor"
#   }

#   set {
#     name  = "prometheus-node-exporter.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key"
#     value = "eks.amazonaws.com/compute-type"
#   }

#   set {
#     name  = "prometheus-node-exporter.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator"
#     value = "NotIn"
#   }

#   set {
#     name  = "prometheus-node-exporter.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].values[0]"
#     value = "fargate"
#   }

#   depends_on = [ module.eks, helm_release.aws-load-balancer-controller ]
# }