#!/bin/bash

source ../shell_setup.sh

gcloud container clusters get-credentials ${VULN_CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT} &> /dev/null
kubectl delete -f clusterrole-anonymous.yaml || true
kubectl delete -f clusterrole-unauthenticated.yaml || true
kubectl delete -f clusterrole-authenticated.yaml || true
kubectl delete -f role-anonymous.yaml || true
kubectl delete -f role-unauthenticated.yaml || true
kubectl delete -f role-authenticated.yaml || true

echo ""
echo ""
pe "kubectl get clusterrolebindings | grep 'ClusterRole/cluster-admin'"
echo ""
echo ""
pe "cat bad-clusterrole-binding.yaml"
echo ""
echo ""
pe "kubectl apply -f bad-clusterrole-binding.yaml"
echo ""
echo ""
pe "kubectl get clusterrolebindings | grep 'bad'"
echo ""
echo ""
pe "kubectl get rolebindings -A | grep 'ClusterRole/cluster-admin'" || true
echo ""
echo ""
pe "cat bad-role-binding.yaml"
echo ""
echo ""
pe "kubectl apply -f bad-role-binding.yaml"
echo ""
echo ""
pe "kubectl get rolebindings -A | grep 'ClusterRole/cluster-admin'"
echo ""
echo ""
pe "kubectl delete -f bad-clusterrole-binding.yaml"
pe "kubectl delete -f bad-role-binding.yaml"
echo ""
echo ""
pe "kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml"
pe "clear"
echo ""
echo ""
# TODO: also cover system:authenticated?
pe "kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper-library/master/library/general/disallowanonymous/template.yaml"
pe "kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper-library/master/library/general/disallowanonymous/samples/no-anonymous-bindings/constraint.yaml"
# Should we cover cluster-admin generally? This command doesn't work, not sure
# where the CRDs are for this.
#pe "kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/acm-policy-controller-library/main/bundles/cis-k8s-v1.5.1/5.1.1_restrict-clusteradmin-rolebindings.yaml"
#kubectl patch K8sRestrictRoleBindings cis-k8s-v1.5.1-restrict-clusteradmin-rolebindings -p '{"spec":{"enforcementAction":"deny"}}'
echo ""
echo ""
pe "kubectl apply -f bad-clusterrole-binding.yaml" || true
echo ""
echo ""
pe "kubectl apply -f bad-role-binding.yaml" || true
echo ""
echo ""
pe "gcloud container clusters get-credentials ${SAFE_CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT}"
echo ""
echo ""
pe "kubectl apply -f bad-clusterrole-binding.yaml" || true
pe "clear"
pe "kubectl apply -f bad-role-binding.yaml" || true
gcloud container clusters get-credentials ${VULN_CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT} &> /dev/null
kubectl delete --wait=false -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml &> /dev/null
