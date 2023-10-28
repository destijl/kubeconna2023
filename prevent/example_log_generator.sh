#!/bin/bash

source ./shell_setup.sh

# Quick script to generate some logs from system:anonymous to help verify
# detection rules

gcloud container clusters get-credentials ${VULN_CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT} &> /dev/null
CLUSTER_IP=$(gcloud container clusters describe ${VULN_CLUSTER_NAME} --zone ${ZONE} --project ${PROJECT} --format="value(endpoint)")

curl -k -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": {
      "name": "my-pod"
    },
    "spec": {
      "containers": [
        {
          "name": "my-container",
          "image": "ubuntu:latest"
        }
      ]
    }
  }' \
  https://${CLUSTER_IP}/api/v1/namespaces/default/pods

curl -k -X DELETE https://${CLUSTER_IP}/api/v1/namespaces/default/pods/my-pod
