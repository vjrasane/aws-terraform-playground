locals {
  cluster_viewer_group = "viewer-group"
  cluster_admin_group  = "admin-group"
}

resource "kubernetes_cluster_role" "viewer" {
  metadata {
    name = "viewer-role"
  }

  rule {
    api_groups = ["*"]
    resources  = ["deployments", "configmaps", "pods", "secrets", "services"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "viewer_role_to_group" {
  metadata {
    name = "viewer-binding"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.viewer.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "Group"
    name      = local.cluster_viewer_group
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_cluster_role_binding" "admin_role_to_group" {
  metadata {
    name = "admin-binding"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "Group"
    name      = local.cluster_admin_group
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"

  chart     = "metrics-server"
  namespace = "kube-system"

  version = "3.12.0"

  values = [file("${path.module}/kubernetes/metrics-server.yml")]

  depends_on = [aws_eks_node_group.eks_node_group]
}

resource "kubernetes_namespace" "demo" {
  metadata {
    name = "demo"
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = "demo-app"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }

  spec {
    selector {
      match_labels = {
        app = "demo-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "demo-app"
        }
      }
      spec {
        container {
          name  = "demo-app"
          image = "aputra/myapp-195:v2"

          port {
            name           = "http"
            container_port = 8080
          }

          resources {
            requests = {
              memory = "256Mi"
              cpu    = "100m"
            }

            limits = {
              memory = "256Mi"
              cpu    = "100m"
            }
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "demo" {
  metadata {
    name      = "demo-app"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment.app.metadata[0].name
    }
    port {
      port        = 8080
      target_port = kubernetes_deployment.app.spec[0].template[0].spec[0].container[0].port[0].name
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "demo" {
  metadata {
    name      = "demo-app"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.app.metadata[0].name
    }

    min_replicas = 1
    max_replicas = 5

    metric {
      type = "Resource"

      resource {
        name = "cpu"

        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }

    metric {
      type = "Resource"

      resource {
        name = "memory"

        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }
  }
}
