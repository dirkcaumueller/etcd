# etcd

Run [etcd](https://etcd.io/) in a Red Hat ubi-minimal container.

## Prerequisites

Install required packages.

```bash
sudo apt update
sudo apt install podman buildah python3-pip
pip3 install podman-compose
```

## Create Container

Switch to user `root`.

```bash
sudo su -
```

Check if etcd container/image already exists and remove them

```bash
buildah rm etcd
buildah rmi etcd
```

Run bash script to create container image.

```bash
./create_ubi_etcd_image.sh
```

Check if container image exists.

```bash
buildah images
```

## Run 3-node etcd Test Cluster

Create a 3-node etcd Cluster to test the container.

```bash
podman-compose up -d
```

Check the cluster member list.

```bash
ETCDCTL_API=3 etcdctl --endpoints localhost:23790,localhost:23791,localhost:23792 member list
```

And validate the cluster health status.

```bash
ETCDCTL_API=3 etcdctl --endpoints localhost:23790,localhost:23791,localhost:23792 endpoint health
```
