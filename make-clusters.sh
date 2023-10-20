#!/bin/bash

source ../shell_setup.sh

# Create cluster
gcloud container clusters create ${VULN_CLUSTER_NAME} \
       --zone=${ZONE} \
       --cluster-version=${VULN_CLUSTER_VERSION} \
       --num-nodes=2

gcloud container clusters create ${SAFE_CLUSTER_NAME} \
       --zone=${ZONE} \
       --cluster-version=${SAFE_CLUSTER_VERSION} \
       --num-nodes=2

