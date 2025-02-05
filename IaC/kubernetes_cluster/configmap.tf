resource "kubernetes_config_map" "fluentbit_config" {
  metadata {
    name      = "fluent-bit-config"
    namespace = "kube-system"
  }

  data = {
    "fluent-bit.conf" = <<-EOT
      [SERVICE]
          Flush         5
          Log_Level     info

      [INPUT]
          Name          tail
          Path          /var/log/containers/*.log
          Tag           containers.*

      [FILTER]
          Name          grep
          Match         containers.*

      [OUTPUT]
          Name          cloudwatch_logs
          Match         containers.*
          region        ap-northeast-2
          log_group_name ${module.eks.cloudwatch_log_group_name}
          log_stream_name containers
          auto_create_group true
    EOT
  }

  depends_on = [module.eks]
}