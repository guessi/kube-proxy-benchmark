#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

UNATTENDED_FLAGS="--ignore-not-found --interactive=false"

echo "* Deleting services with name pattern nginx-service-*..."
kubectl -n debug get services --no-headers | \
  awk '/nginx-service-/{print$1}' | \
  sort -r | \
  xargs -r -n 100 \
    kubectl -n debug delete service ${UNATTENDED_FLAGS}
echo

echo "* Deleting deployment..."
kubectl -n debug delete deployment nginx-deployment ${UNATTENDED_FLAGS}
echo

echo "* Deleting namespace..."
kubectl delete namespace debug ${UNATTENDED_FLAGS}
echo

echo "* Cleanup completed!"
