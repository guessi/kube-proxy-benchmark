# kube-proxy Benchmark

Performance testing to compare Linux kernel version impact on kube-proxy `nftables` mode performance.

## Overview

This repository benchmarks kube-proxy performance in `nftables` mode across different Linux kernel versions. The test compares sync rule processing times between kernel versions `6.1.144` and `6.12.46`.

**Test Result**: Kernel `6.12.46` shows **73% faster** performance compared to `6.1.144` in this benchmark.

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
- EKS cluster with Kubernetes v1.34
- Two Bottlerocket-based nodes:
  - `m5.4xlarge` × 1 (kernel `v6.1.144`)
  - `m5.4xlarge` × 1 (kernel `v6.12.46`)
- `kube-proxy` version `v1.32.6-eksbuild.12` in `nftables` mode

### Verify Cluster

```bash
# Check nodes and kernel versions
kubectl get nodes -o wide

# Verify infra containers are running
kubectl get pods -n kube-system
```

## Test Methodology

This benchmark creates a high-load scenario to test kube-proxy's `nftables` rule synchronization:

1. **Service Creation**: Create `8,000 services` incrementally (100 to 8,000)
2. **Service Configuration**: Each service targets the same nginx deployment
3. **Stabilization**: Wait `300 seconds` for service processing to complete
4. **Trigger Event**: Scale deployment from `1` to `30` replicas incrementally (60 seconds between each step)
5. **Measurement**: Measure kube-proxy `nftables` rule synchronization time

## Quick Start

### Step 1: Generate Test Workload

```bash
./scripts/generate.sh
```

**What this script does:**

- Creates a `debug` namespace
- Deploys nginx with `1` replica (initial state)
- Creates `8,000` services incrementally

### Step 2: Increase Load (Trigger Performance Test)

```bash
./scripts/increase-loading.sh
```

**What this script does:**

- Scales deployment from `1 (initial state)` to `5`, to `30` replicas incrementally (triggers the performance test)

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
- **Instance Type**: `m5.4xlarge`
- **kube-proxy Version**: `v1.32.6-eksbuild.12`
- **Services**: `8,000`
- **Replicas per Service**: `30`
- **Total Endpoints**: `240,000`

### Results Summary

| Kernel Version | Instance   | Sync Duration | Average      |
|----------------|------------|---------------|--------------|
| `6.12.46`      | m5.4xlarge | 4m 50.5s      | **4m 0.1s**  |
| `6.12.46`      | m5.4xlarge | 5m 34.1s      |              |
| `6.12.46`      | m5.4xlarge | 1m 22.0s      |              |
| `6.12.46`      | m5.4xlarge | 4m 54.4s      |              |
| `6.1.144`      | m5.4xlarge | 16m 31.5s     | **15m 0.1s** |
| `6.1.144`      | m5.4xlarge | 12m 47.4s     |              |
| `6.1.144`      | m5.4xlarge | 12m 12.1s     |              |
| `6.1.144`      | m5.4xlarge | 15m 26.2s     |              |
| `6.1.144`      | m5.4xlarge | 19m 3.5s      |              |

**Performance Improvement**: Kernel `6.12.46` is **73% faster** than `6.1.144` (4m 0s vs 15m 0s average)

> **The tests were performed on Oct 15, 2025**

## Key Findings

### Performance Impact

- **Performance Difference**: Kernel `6.12.46` reduces `nftables` rule synchronization time by **73%** in this test
- **Scale Impact**: The performance difference becomes more pronounced at scale (240,000 endpoints)
- **Observed Results**: In this benchmark, newer kernel versions show performance differences for large Kubernetes clusters

## Technical Details

### What We Measured

- **Target**: kube-proxy's `nftables` mode (default for modern Kubernetes)
- **Focus**: `SyncProxyRules` operation (used for service discovery)
- **Scope**: Large-scale service configurations

### Important Considerations

- Results may vary based on hardware specifications
- Network configuration can impact performance
- Cluster topology affects synchronization times

## Limitations

This benchmark has several important limitations:

- **Hardware Specific**: Tests conducted on `m5.4xlarge` instances
- **Kernel Specific**: Results apply to tested versions (`6.1.144` vs `6.12.46`)
- **Scale Specific**: Performance improvements may vary with different cluster sizes
- **Workload Specific**: Results based on specific service/endpoint patterns
