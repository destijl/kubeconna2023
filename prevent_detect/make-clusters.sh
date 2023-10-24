#!/bin/bash

source ../shell_setup.sh

gcloud config set project ${PROJECT}

# Create cluster
gcloud container clusters create ${VULN_CLUSTER_NAME} \
       --zone=${ZONE} \
       --cluster-version=${VULN_CLUSTER_VERSION} \
       --num-nodes=2

gcloud container clusters create ${SAFE_CLUSTER_NAME} \
       --zone=${ZONE} \
       --release-channel "rapid" \
       --cluster-version=${SAFE_CLUSTER_VERSION} \
       --num-nodes=2

