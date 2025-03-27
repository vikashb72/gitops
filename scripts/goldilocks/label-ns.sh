#!/usr/bin/env bash

for ns in $(kubectl get ns -o name)
do
    kubectl label $ns goldilocks.fairwinds.com/enabled=true
done
