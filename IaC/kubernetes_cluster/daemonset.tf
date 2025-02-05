resource "kubernetes_daemonset" "fluent_bit" {
  metadata {
    name      = "fluent-bit"
    namespace = "kube-system"
    labels = {
      "k8s-app" = "fluent-bit"
    }
  }

  spec {
    selector {
      match_labels = {
        "k8s-app" = "fluent-bit"
      }
    }

    template {
      metadata {
        labels = {
          "k8s-app" = "fluent-bit"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.fluentbit_sa.metadata[0].name

        container {
          name  = "fluent-bit"
          image = "fluent/fluent-bit:latest"

          resources {
            limits = {
              memory = "200Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "100Mi"
            }
          }

          volume_mount {
            name       = "varlog"
            mount_path = "/var/log/containers"
            read_only  = true
          }

          volume_mount {
            name       = "config"
            mount_path = "/fluent-bit/etc/"
          }
        }

        volume {
          name = "varlog"
          host_path {
            path = "/var/log/containers"
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.fluentbit_config.metadata[0].name
          }
        }
      }
    }
  }
}