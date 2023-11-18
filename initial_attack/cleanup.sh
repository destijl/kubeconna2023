rm csr.key csr.crt csr.csr attacker_persistence_csr.yaml
kubectl delete clusterrolebinding cluster-system-anonymous
kubectl delete clusterrolebinding kube-controller-manager
kubectl delete clusterrolebinding kube-controller-admin
kubectl delete daemonset kube-controller -n kube-system
gcloud container clusters delete vuln-cluster
