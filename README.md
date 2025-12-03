# kube-proxy Benchmark

Performance testing to compare Linux kernel version impact on kube-proxy `nftables` mode performance.

## Overview

This repository benchmarks kube-proxy performance in `nftables` mode across different Linux kernel versions. The test compares sync rule processing times between kernel versions `6.1.144` and `6.12.55`.

**Test Result**: Kernel `6.12.55` shows **77% faster** performance compared to `6.1.144` in this benchmark.

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

- EKS cluster with Kubernetes v1.33
- Two Bottlerocket-based nodes:
  - `m6i.8xlarge` × 1 (kernel `v6.1.144`)
  - `m6i.8xlarge` × 1 (kernel `v6.12.55`)
- `kube-proxy` version `v1.33.5-eksbuild.2` in `nftables` mode

### Verify Cluster

```bash
# Check nodes and kernel versions
kubectl get nodes -o wide

# Verify infra containers are running
kubectl get pods -n kube-system
```

## Test Methodology

This benchmark creates a high-load scenario to test kube-proxy's `nftables` rule synchronization:

1. **Service Creation**: Create `8,000 services` incrementally (100 to 5,000)
2. **Service Configuration**: Each service targets the same nginx deployment
3. **Stabilization**: Wait `300 seconds` for service processing to complete
4. **Trigger Event**: Scale deployment from `10` to `50` replicas incrementally (10 seconds between each step)
5. **Measurement**: Measure kube-proxy `nftables` rule synchronization time

## Quick Start

### Step 1: Generate Test Workload

```bash
./scripts/generate.sh
```

**What this script does:**

- Creates a `debug` namespace
- Deploys nginx with `10` replicas (initial state)
- Creates `5,000` services incrementally

### Step 2: Increase Load (Trigger Performance Test)

```bash
./scripts/increase-loading.sh
```

**What this script does:**

- Scales deployment from `10 (initial state)` to `20`, to `50` replicas incrementally (triggers the performance test)

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

## Performance Results

### Test Configuration

- **Operating System**: `Bottlerocket`
- **Instance Type**: `m6i.8xlarge`
- **kube-proxy Version**: `v1.33.5-eksbuild.2`
- **Services**: `5,000`
- **Replicas per Service**: `50`
- **Total Endpoints**: `250,000`

### Results Summary

**Performance Improvement**: Kernel `6.12.55` is **77% faster** than `6.1.144` (2m 12s vs 9m 27s average)

> **The tests were performed on Nov 29, 2025**

## Key Findings

### Performance Impact

- **Performance Difference**: Kernel `6.12.55` reduces `nftables` rule synchronization time by **77%** in this test
- **Scale Impact**: The performance difference becomes more pronounced at scale (250,000 endpoints)
- **Observed Results**: In this benchmark, newer kernel versions show performance differences for large Kubernetes clusters

## Technical Details

### What We Measured

- **Target**: kube-proxy's `nftables` mode (default for modern Kubernetes)
- **Focus**: `SyncProxyRules` operation (used for service discovery)
- **Scope**: Large-scale service configurations

### Observed Kernel Behavior

During testing, both kernels experienced "soft lockups" - situations where the CPU gets stuck processing for an extended time without responding to other tasks. System logs reveal significant differences:

- **Kernel 6.1.144**: CPU stuck for up to **701 seconds (11m 41s)** with 200 lockup events
- **Kernel 6.12.55**: CPU stuck for up to **104 seconds (1m 44s)** with 13 lockup events

**What causes the lockup?**

When kube-proxy updates firewall rules for 250,000+ endpoints, the kernel
needs to:

1. Search through existing firewall rule sets to find the right ones
2. Link new rules to those sets

On kernel 6.1.144, the search operation is very slow - the CPU spends most of
its time looking through rules. On kernel 6.12.55, this search is much faster,
resulting in 6.7x shorter lockup times. This improvement directly explains the
77% better overall performance.

### Important Considerations

- Results may vary based on hardware specifications
- Network configuration can impact performance
- Cluster topology affects synchronization times

## Limitations

This benchmark has several important limitations:

- **Hardware Specific**: Tests conducted on `m6i.8xlarge` instances
- **Kernel Specific**: Results apply to tested versions (`6.1.144` vs `6.12.55`)
- **Scale Specific**: Performance improvements may vary with different cluster sizes
- **Workload Specific**: Results based on specific service/endpoint patterns
