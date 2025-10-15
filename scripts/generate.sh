#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCALES=($(seq 100 100 8000))

# Create namespace
kubectl create namespace debug \
  --dry-run=client -o yaml | kubectl apply -f -

# Create deployment
kubectl --namespace=debug create deployment nginx-deployment \
  --image=nginx:stable-alpine \
  --port=80 \
  --replicas=1 \
  --dry-run=client -o yaml | \
  kubectl apply --force-conflicts -f -

# Patch deployment to disable service links
kubectl patch deployment nginx-deployment -n debug -p '{"spec":{"template":{"spec":{"enableServiceLinks":false}}}}'

# Check existing services to determine starting point
echo "Checking existing services..."
EXISTING_SERVICES=$(kubectl get services -n debug --no-headers 2>/dev/null | grep "nginx-service-" | wc -l | tr -d '\n' || echo "0")
CURRENT_COUNT=$EXISTING_SERVICES
echo "Found $CURRENT_COUNT existing services"

for TARGET_COUNT in "${SCALES[@]}"; do
  # Skip if we already have this many or more services
  if [[ $CURRENT_COUNT -ge $TARGET_COUNT ]]; then
    echo "Skipping target $TARGET_COUNT (already have $CURRENT_COUNT services)"
    continue
  fi

  NEW_SERVICES=$((TARGET_COUNT - CURRENT_COUNT))
  echo "========================================="
  echo "Adding $NEW_SERVICES services (total: $TARGET_COUNT)..."
  echo "========================================="

  # Generate only new services
  echo "Applying $NEW_SERVICES new services to cluster..."
  for i in $(seq $((CURRENT_COUNT + 1)) $TARGET_COUNT); do
    [[ $i -gt $((CURRENT_COUNT + 1)) ]] && echo "---"
    cat <<EOF
apiVersion: v1
kind: Service
metadata:
  name: nginx-service-$(printf "%05d" $i)
  namespace: debug
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: nginx-deployment
  type: ClusterIP
EOF
  done | kubectl apply -f -

  CURRENT_COUNT=$TARGET_COUNT
  echo "Total services now: $CURRENT_COUNT"
  echo ""
done
