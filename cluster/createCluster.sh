#!/usr/bin/env bash

# create cluster
eksctl create cluster -f ./clusterConfig.yaml

# (Optional) remove unnecessary addons
# eksctl delete addon --cluster eks-reproduce --name coredns
# eksctl delete addon --cluster eks-reproduce --name metrics-server
