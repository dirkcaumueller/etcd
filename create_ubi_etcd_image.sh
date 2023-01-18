#!/bin/bash

# Set etcd version and download URL
ETCD_VERSION=v3.5.6
DOWNLOAD_URL=https://github.com/etcd-io/etcd/releases/download

# Download and extract etcd
curl -L ${DOWNLOAD_URL}/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz -o etcd-${ETCD_VERSION}-linux-amd64.tar.gz

# Extract etcd binaries
tar -zxvf etcd-${ETCD_VERSION}-linux-amd64.tar.gz \
    etcd-${ETCD_VERSION}-linux-amd64/etcd \
    etcd-${ETCD_VERSION}-linux-amd64/etcdctl \
    etcd-${ETCD_VERSION}-linux-amd64/etcdutl \
    --strip-components=1

# Remove old container
buildah rm etcd

# Create a minimal container based on ubi-minimal image
newcontainer=$(buildah from --name=etcd registry.access.redhat.com/ubi8/ubi-minimal)

# Configure the container
buildah config --created-by "Dirk Aumueller" \
               --author "Dirk Aumueller" $newcontainer
buildah config --label name=dca \
               --label app=etcd $newcontainer

# Create etcd group and user
buildah run $newcontainer microdnf install shadow-utils libsemanage
buildah run $newcontainer groupadd etcd
buildah run $newcontainer useradd -g etcd -m etcd
buildah run $newcontainer microdnf remove shadow-utils libsemanage
buildah run $newcontainer microdnf clean all
buildah config --user etcd:etcd $newcontainer
buildah config --workingdir /home/etcd $newcontainer

# Copy etcd binaries into image
buildah copy $newcontainer ./etcd /usr/local/bin/etcd
buildah copy $newcontainer ./etcdctl /usr/local/bin/etcdctl
buildah copy $newcontainer ./etcdutl /usr/local/bin/etcdutl

# Create a data directory
buildah run --user root $newcontainer mkdir -p /etcddata
buildah run --user root $newcontainer chown etcd:etcd /etcddata
buildah config --volume /etcddata $newcontainer

# Open ports
buildah config --port 2379 \
               --port 2380 $newcontainer

# Set environment variables
buildah config --env APP_NAME="etcd" \
               --env APP_VERSION="${ETCD_VERSION}" \
               --env ETCDCTL_API="3" \
               --env ETCD_DATA_DIR="/etcddata" $newcontainer

# Set entrypoint
buildah config --entrypoint /usr/local/bin/etcd $newcontainer

# Unmount container and create image
buildah unmount $newcontainer
buildah commit $newcontainer etcd:${ETCD_VERSION}

# Remove downloaded etcd binaries
rm -f etcd-${ETCD_VERSION}-linux-amd64.tar.gz etcd etcdctl etcdutl
