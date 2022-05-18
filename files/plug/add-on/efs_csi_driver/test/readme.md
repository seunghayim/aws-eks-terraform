kubectl get pods -n kube-system | grep efs-csi-controller

# 이름 변경
kubectl logs efs-csi-controller-74ccf9f566-q5989 \
    -n kube-system \
    -c csi-provisioner \
    --tail 10

kubectl get pv

kubectl get pvc

kubectl get pods -o wide

kubectl exec efs-app -- bash -c "cat data/out"

kubectl delete -k .