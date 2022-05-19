#!/usr/bin/env sh

eksctl create iamserviceaccount \
  --cluster multi05-eks-cluster-terraform \
  --namespace default \
  --name xray-daemon \
  --attach-policy-arn  arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess \
  --override-existing-serviceaccounts \
  --approve

# Apply a label to the service account
kubectl label serviceaccount xray-daemon app=xray-daemon

# To deploy the X-Ray DaemonSet
kubectl create -f https://eksworkshop.com/intermediate/245_x-ray/daemonset.files/xray-k8s-daemonset.yaml

