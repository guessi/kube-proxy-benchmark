#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

while true; do
  # Randomly kill few pods to simulate a normal scale, so that it could trigger kube-proxy rules update
  kubectl -n debug get pods --no-headers | awk '/Running/{print$1}' | tail -3 | xargs kubectl -n debug delete po --force --interactive=false

  echo "Waiting 300 seconds after scaling..."
  sleep 300
done
