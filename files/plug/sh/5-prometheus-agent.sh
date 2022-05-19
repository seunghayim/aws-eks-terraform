#!/usr/bin/env sh

eksctl create iamserviceaccount \
 --name cwagent-prometheus \
--namespace amazon-cloudwatch \
 --cluster multi05-eks-cluster-terraform \
--attach-policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
--approve \
--override-existing-serviceaccounts

# amazon-cloudwatch 생성 여부 확인
kubectl get namespace

# 없으면 생성
# kubectl create namespace amazon-cloudwatch

# 배포
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/service/cwagent-prometheus/prometheus-eks.yaml

