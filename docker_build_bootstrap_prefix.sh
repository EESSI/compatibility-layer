#!/bin/bash

cpu_arch=$(uname -m)
tag="eessi/bootstrap-prefix:centos8-${cpu_arch}"

echo "Building EESSI container for bootstrapping Prefix on ${cpu_arch}..."
docker build --no-cache -f Dockerfile.bootstrap-prefix-centos8-${cpu_arch} -t ${tag} .

echo "Pushing ${tag} to Docker Hub..."
docker push eessi/bootstrap-prefix:centos8-${cpu_arch}
