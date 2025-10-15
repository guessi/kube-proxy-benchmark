#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

echo "Deleting services with name pattern nginx-service-*..."
kubectl --namespace=debug delete services -l '!kubernetes.io/service-name' --ignore-not-found=true || \
kubectl --namespace=debug get services --no-headers | grep "nginx-service-" | awk '{print $1}' | xargs -r kubectl --namespace=debug delete service

echo "Deleting deployment..."
kubectl --namespace=debug delete deployment nginx-deployment --ignore-not-found=true

echo "Deleting namespace..."
kubectl delete namespace debug --ignore-not-found=true

echo "Cleanup completed!"
