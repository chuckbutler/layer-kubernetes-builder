#!/bin/bash
set -ex

source charms.reactive.sh


@when_not 'docker.configured'
function install_kubernetes-builder() {
  usermod -G docker jenkins

  # Reconfigure docker to use AUFS instead of DeviceMapper
  apt update -y
  apt install -y aufs-tools \
                 linux-image-extra-`uname -r` \
                 git

  cat << EOF > /etc/default/docker.io
# THIS FILE IS MANAGED BY A BUILD SCRIPT!
DOCKER_OPTS="--storage-driver=aufs"
EOF


  # restart jenkins so it can access docker
  service jenkins restart

  charms.reactive set_state 'docker.configured'
}


reactive_handler_main
