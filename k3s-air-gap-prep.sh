#!/usr/bin/env bash
# https://docs.k3s.io/installation/airgap
# Select release : https://github.com/k3s-io/k3s/releases
v=v1.31.3 # K8s version available at K3s

# Pull K3s-images archive
tarball=k3s-airgap-images-amd64.tar.gz
curl -sSLO https://github.com/k3s-io/k3s/releases/download/${v}%2Bk3s1/$tarball

# Load all images (later/elsewhere) into local cache 
# for subsequent tag/push to private registry of target air-gap environment.
type -t docker &&
    docker load -i $tarball

# Pull k3s CLI
curl -sSLO https://github.com/k3s-io/k3s/releases/download/${v}%2Bk3s1/k3s