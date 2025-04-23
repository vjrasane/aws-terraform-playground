
locals {
  env          = "staging"
  cluster_name = "staging-demo"
  region       = "eu-north-1"
  zones = [
    "eu-north-1a",
    "eu-north-1b",
  ]
  eks_version  = "1.29"
}


