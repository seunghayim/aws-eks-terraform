kubectl describe storageclass ebs-sc

kubectl get pods --watch

kubectl get pv

# 이전 출력값 참조
kubectl describe pv pvc-37717cd6-d0dc-11e9-b17f-06fad4858a5a

kubectl exec -it app -- cat /data/out.txt

kubectl delete -k .