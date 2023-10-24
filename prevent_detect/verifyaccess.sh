#!/bin/bash

# $Id: $
source ../shell_setup.sh

# Quick and dirty script to verify all the dimensions of acccess with
# misconfigured RBAC. Too much to cover every case in the talk.

GMAIL_USER="replaceme"
gcloud container clusters get-credentials ${VULN_CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT} &> /dev/null
CLUSTER_IP=$(gcloud container clusters describe ${VULN_CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT} --format="value(endpoint)")

kubectl delete -f clusterrole-anonymous.yaml || true
kubectl delete -f clusterrole-unauthenticated.yaml || true
kubectl delete -f clusterrole-authenticated.yaml || true
kubectl delete -f role-anonymous.yaml || true
kubectl delete -f role-unauthenticated.yaml || true
kubectl delete -f role-authenticated.yaml || true

# Cluster to anonymous
curl --fail-with-body -k -X GET https://${CLUSTER_IP}/api/v1/pods || true
kubectl apply -f clusterrole-anonymous.yaml
curl --fail-with-body -k -X GET https://${CLUSTER_IP}/api/v1/pods &> /dev/null
kubectl delete -f clusterrole-anonymous.yaml
kubectl wait clusterrolebinding.rbac.authorization.k8s.io/bad-clusterrole-binding --for=delete --timeout=-1s

# Cluster to unauthenticated
curl --fail-with-body -k -X GET https://${CLUSTER_IP}/api/v1/pods || true
kubectl apply -f clusterrole-unauthenticated.yaml
curl --fail-with-body -k -X GET https://${CLUSTER_IP}/api/v1/pods &> /dev/null 
kubectl delete -f clusterrole-unauthenticated.yaml
kubectl wait clusterrolebinding.rbac.authorization.k8s.io/bad-clusterrole-group-binding --for=delete --timeout=-1s

# Cluster to authenticated
curl --fail-with-body -k -X GET \
  https://${CLUSTER_IP}/api/v1/pods \
  -H "Authorization: Bearer $(gcloud auth print-access-token ${GMAIL_USER})" || true
kubectl apply -f clusterrole-authenticated.yaml
curl --fail-with-body -k -X GET \
  https://${CLUSTER_IP}/api/v1/pods \
  -H "Authorization: Bearer $(gcloud auth print-access-token ${GMAIL_USER})" &> /dev/null
kubectl delete -f clusterrole-authenticated.yaml
kubectl wait clusterrolebinding.rbac.authorization.k8s.io/bad-clusterrole-authenticated-binding --for=delete --timeout=-1s

# Role to anonymous
curl --fail-with-body -k -X GET https://${CLUSTER_IP}/api/v1/namespaces/kube-system/pods || true
kubectl apply -f role-anonymous.yaml
curl --fail-with-body -k -X GET https://${CLUSTER_IP}/api/v1/namespaces/kube-system/pods &> /dev/null
kubectl delete -f role-anonymous.yaml
kubectl wait rolebinding.rbac.authorization.k8s.io/bad-role-binding --for=delete --timeout=-1s

# Role to unauthenticated
curl --fail-with-body -k -X GET https://${CLUSTER_IP}/api/v1/namespaces/kube-system/pods || true
kubectl apply -f role-unauthenticated.yaml
curl --fail-with-body -k -X GET https://${CLUSTER_IP}/api/v1/namespaces/kube-system/pods &> /dev/null
kubectl delete -f role-unauthenticated.yaml
kubectl wait rolebinding.rbac.authorization.k8s.io/bad-role-group-binding --for=delete --timeout=-1s

# Role to authenticated
curl --fail-with-body -k -X GET \
  https://${CLUSTER_IP}/api/v1/namespaces/kube-system/pods \
  -H "Authorization: Bearer $(gcloud auth print-access-token ${GMAIL_USER})" || true
kubectl apply -f role-authenticated.yaml
curl --fail-with-body -k -X GET \
  https://${CLUSTER_IP}/api/v1/namespaces/kube-system/pods \
  -H "Authorization: Bearer $(gcloud auth print-access-token ${GMAIL_USER})" &> /dev/null
kubectl delete -f role-authenticated.yaml

echo "Success!"
