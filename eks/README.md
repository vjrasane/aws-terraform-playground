
```shell
aws sts get-caller-identity --profile ville
```

```shell
aws eks update-kubeconfig --region eu-north-1 --name staging-demo --profile ville
```

```shell
kubectl auth can-i "*" "*"
```

```shell
kubectl config view --minify
```

```shell
kubectl auth can-i get pods
```

```shell
aws sts assume-role --role-arn arn:aws:iam::838319850436:role/staging-demo-admin-role --role-session-name manager-session --profile ville_admin
```

```
[profile eks_admin]
role_arn = arn:aws:iam::838319850436:role/staging-demo-admin-role 
source_profile = ville
```