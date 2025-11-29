#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

TARGET_REPLICAS=50

for replicas in $(seq 5 5 $TARGET_REPLICAS); do
  CURRENT_REPLICA=$(kubectl --namespace debug get deployment nginx-deployment -o json | jq -r .spec.replicas)
  if [[ $CURRENT_REPLICA -lt $replicas ]]; then
    kubectl --namespace=debug scale deployment nginx-deployment --replicas $replicas

    echo "Waiting 30 seconds after scaling setting replica count to $replicas..."
    sleep 30
  fi
done
