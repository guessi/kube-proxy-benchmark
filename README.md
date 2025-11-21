# kube-proxy Benchmark

Performance testing to compare Linux kernel version impact on kube-proxy `nftables` mode performance.

## Overview

This repository benchmarks kube-proxy performance in `nftables` mode, focus on kernel version `6.1.144` only.

## Prerequisites

Before running this benchmark, ensure you have:

- [eksctl](https://eksctl.io/) installed and configured
- AWS CLI configured with appropriate permissions
- `kubectl` installed

## Cluster Setup

### Create EKS Cluster

Create the benchmark cluster with two nodes running different kernel versions:

```bash
eksctl create cluster -f cluster/clusterConfig.yaml
```

This creates:
- EKS cluster with Kubernetes v1.33, detail setup could be found at `cluster/clusterConfig.yaml`

### Verify Cluster

```bash
# Check nodes and kernel versions
kubectl get nodes -o wide

# Verify infra containers are running
kubectl get pods -n kube-system
```

## Test Methodology

This benchmark creates a high-load scenario to test kube-proxy's `nftables` rule synchronization:

1. **Service Creation**: Create `3,500 services` incrementally (100 to 3,500)
2. **Service Configuration**: Each service targets the same nginx deployment
3. **Stabilization**: Wait `300 seconds` for service processing to complete
4. **Trigger Event**: Scale deployment from `1` to `50` replicas incrementally (60 seconds between each step)
5. **Measurement**: Measure kube-proxy `nftables` rule synchronization time

## Quick Start

### Step 1: Generate Test Workload

```bash
./scripts/generate.sh
```

**What this script does:**

- Creates a `debug` namespace
- Deploys nginx with `1` replica (initial state)
- Creates `3,500` services incrementally

### Step 2: Increase Load (Trigger Performance Test)

```bash
./scripts/increase-loading.sh
```

**What this script does:**

- Scales deployment from `1 (initial state)` to `5`, to `50` replicas incrementally (triggers the performance test)

### Step 3: Monitor Performance Logs

Open a separate terminal and run:

```bash
# Find kube-proxy pods
kubectl get pods -n kube-system -l k8s-app=kube-proxy -o wide

# Monitor logs for sync duration
kubectl logs -n kube-system -f <KUBE_PROXY_POD_NAME>
```

**What to look for:** Log entries containing `"SyncProxyRules complete"` with elapsed time measurements.

### Step 4: Clean Up Resources

```bash
./scripts/cleanup.sh
```
