#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

TARGET_REPLICAS=30

for replicas in $(seq 5 5 $TARGET_REPLICAS); do
  echo "Waiting 60 seconds before scaling setting replica count to $replicas..."
  sleep 60

  kubectl --namespace=debug scale deployment nginx-deployment --replicas $replicas
done
