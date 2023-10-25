#!/bin/bash

source ../shell_setup.sh

gcloud container clusters get-credentials ${VULN_CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT} &> /dev/null
CLUSTER_IP=$(gcloud container clusters describe ${VULN_CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT} --format="value(endpoint)")
kubectl delete -f clusterrole-anonymous.yaml &>/dev/null || true
kubectl delete -f clusterrole-unauthenticated.yaml &>/dev/null || true
kubectl delete -f clusterrole-authenticated.yaml &>/dev/null || true
kubectl delete -f role-anonymous.yaml &>/dev/null || true
kubectl delete -f role-unauthenticated.yaml &>/dev/null || true
kubectl delete -f role-authenticated.yaml &>/dev/null || true
kubectl delete --wait=false -f gatekeeper/gatekeeper.yaml &> /dev/null || true

echo ""
echo ""
pe "curl -k https://${CLUSTER_IP}/api/v1/secrets"
pe "clear"
echo ""
echo ""
pe "cat clusterrole-anonymous.yaml"
echo ""
echo ""
pe "kubectl apply -f clusterrole-anonymous.yaml"
echo ""
echo ""
pe "curl -ks https://${CLUSTER_IP}/api/v1/secrets | jq -r '.items[].metadata.name'"
pe "clear"
echo ""
echo ""
pe "kubectl delete -f clusterrole-anonymous.yaml"
echo ""
echo ""
pe "kubectl apply -f gatekeeper/gatekeeper.yaml"
pe "clear"
echo ""
echo ""
pe "kubectl apply -f gatekeeper/disallowanonymous_template.yaml"
pe "kubectl apply -f gatekeeper/disallowanonymous_constraint.yaml"
pe "clear"
echo ""
echo ""
pe "kubectl apply -f clusterrole-anonymous.yaml
-f clusterrole-authenticated.yaml
-f clusterrole-unauthenticated.yaml
-f role-anonymous.yaml
-f role-authenticated.yaml
-f role-unauthenticated.yaml" || true
# Should we cover cluster-admin generally? This command doesn't work, not sure
# where the CRDs are for this.
#pe "kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/acm-policy-controller-library/main/bundles/cis-k8s-v1.5.1/5.1.1_restrict-clusteradmin-rolebindings.yaml"
#kubectl patch K8sRestrictRoleBindings cis-k8s-v1.5.1-restrict-clusteradmin-rolebindings -p '{"spec":{"enforcementAction":"deny"}}'
pe "clear"
echo ""
echo ""
pe "gcloud container clusters get-credentials ${SAFE_CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT}"
echo ""
echo ""
pe "kubectl apply -f clusterrole-anonymous.yaml
-f clusterrole-authenticated.yaml
-f clusterrole-unauthenticated.yaml
-f role-anonymous.yaml
-f role-authenticated.yaml
-f role-unauthenticated.yaml" || true
gcloud container clusters get-credentials ${VULN_CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT} &> /dev/null
kubectl delete --wait=false -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml &> /dev/null || true

