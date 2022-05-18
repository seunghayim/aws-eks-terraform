#!/usr/bin/env sh
kubectl apply \
    --validate=false \
    -f https://github.com/jetstack/cert-manager/releases/download/v1.5.4/cert-manager.yaml

# 컨트롤러 설치 확인
# kubectl get deployment -n kube-system aws-load-balancer-controller
# autoscaler 로그 확인
# kubectl -n kube-system logs -f deployment.apps/cluster-autoscaler

kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"