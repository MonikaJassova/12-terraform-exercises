resource "helm_release" "mysql" {
  name       = "mysql-release"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mysql"
  namespace  = "default"
  timeout    = "1000"
  version    = "9.4.0"

  values = ["${file("${path.module}/mysql-values.yaml")}"]

  depends_on = [module.base]
  atomic     = true
}
