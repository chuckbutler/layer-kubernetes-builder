#!/bin/bash
set -ex

source charms.reactive.sh

JENKINS_WORKSPACE_DIR=/var/lib/jenkins/jobs

@when_not 'kubernetes-builder workload_builder.configured'
function install_kubernetes-builder() {
  status-set "maintenance" "Configuring workspace environment pre-conditions"

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
  service docker restart

  charms.reactive set_state 'kubernetes-builder workload_builder.configured'
}


@when_not 'workspace.payload-delivered'
function deliver_resource_payload() {
  set +e
  WORKSPACEZIP=$(resource-get workspace)
  set -e
  if [[ $? != 0 || -z $WORKSPACEZIP ]]; then
     status-set "waiting" "Waiting on workspace to be provided"
     return
  fi

  if [ ! -z "${WORKSPACEZIP}" ]; then
     cp $WORKSPACEZIP $JENKINS_WORKSPACE_DIR/delivery.zip
     cd $JENKINS_WORKSPACE_DIR
     unzip delivery.zip
     rm delivery.zip
     chown -R jenkins:jenkins *
     service jenkins restart
     status-set "active" "Workspace unpacked."
     charms.reactive set_state 'workspace.payload-delivered'
  fi
}
reactive_handler_main
