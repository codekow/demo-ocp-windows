#!/bin/bash

# https://docs.openshift.com/container-platform/4.10/installing/installing_vsphere/installing-vsphere-installer-provisioned.html#installation-vsphere-installer-infra-requirements_installing-vsphere-installer-provisioned

VSPHERE_ROLES='
  openshift-vcenter-level
  openshift-cluster-level
  openshift-resource-pool-level
  openshift-datastore-level
  openshift-portgroup-level
  openshift-folder-level
  openshift-datacenter-level
'

setup_bin() {
  TMP_DIR=$(pwd)/generated
  mkdir -p ${TMP_DIR}/bin
  echo ${PATH} | grep -q "${TMP_DIR}/bin" || \
    export PATH=${TMP_DIR}/bin:$PATH

  download_govc
}

check_govc() {
which govc >/dev/null || setup_bin
}

download_govc() {
  DOWNLOAD_URL=https://github.com/vmware/govmomi/releases/download/v0.29.0/govc_Linux_x86_64.tar.gz
  curl "${DOWNLOAD_URL}" -L | tar vzx -C ${TMP_DIR}/bin govc
}

print_usage() {
echo "Usage: . hacks/vsphere_roles.sh"
echo "
  Run: vsphere_{dump_roles,create_roles,remove_roles,diff_roles}
"

}

read_login() {
  
if [ ! "${GOVC_URL}x" == "x" ]; then
  print_usage
  echo 'run: "unset GOVC_URL" to reset login'
else
  GOVC_URL=10.1.2.3
  GOVC_USERNAME=Administrator
  read -p "vSphere Host/IP [${GOVC_URL}]: " GOVC_URL
  read -p "vSphere User [${GOVC_USERNAME}]: " GOVC_USERNAME
  read -p "vSphere Password: " -s GOVC_PASSWORD
  echo
  
  GOVC_URL=${GOVC_URL:-10.1.2.3}
  GOVC_USERNAME=${GOVC_USERNAME:-Administrator}
  GOVC_INSECURE=${GOVC_INSECURE:-true}
  
  export GOVC_URL="${GOVC_USERNAME}:${GOVC_PASSWORD}@${GOVC_URL}"
  
  echo "GOVC_INSECURE: ${GOVC_INSECURE}"
  print_usage

fi
}

vsphere_dump_roles() {

for ROLE in ${VSPHERE_ROLES}
do
  echo "ROLE: ${ROLE}"
  govc role.ls "${ROLE}" | tee generated/role.${ROLE}
  echo
done
}

vsphere_create_roles() {

for ROLE in ${VSPHERE_ROLES}
do
  govc role.create ${ROLE}
  govc role.update ${ROLE} $(cat conf/vsphere/role.${ROLE})
done
}

vsphere_remove_roles() {

for ROLE in ${VSPHERE_ROLES}
do
  echo govc role.remove ${ROLE}
done
}

vsphere_diff_roles() {

vsphere_dump_roles

for ROLE in ${VSPHERE_ROLES}
do
  diff -u conf/vsphere/role.${ROLE} generated/role.${ROLE}
done
}

check_govc
read_login
