#!/bin/bash
# see https://projectcalico.docs.tigera.io/getting-started/windows-calico/openshift/installation
# set -x

INSTALL_DIR=ocp
TMP_DIR=generated
unset KUBECONFIG

setup_bin() {
  mkdir -p ${TMP_DIR}/bin
  echo ${PATH} | grep -q "${TMP_DIR}/bin" || \
    export PATH=$(pwd)/${TMP_DIR}/bin:$PATH
}

check_ocp_install() {
  which openshift-install 2>&1 >/dev/null || download_ocp_install
  echo "auto-complete: . <(openshift-install completion bash)"
  . <(openshift-install completion bash)
  openshift-install version
  sleep 5
}

check_oc() {
  which oc 2>&1 >/dev/null || download_oc
  echo "auto-complete: . <(oc completion bash)"
  . <(oc completion bash)
  oc version
  sleep 5
}

check_kustomize() {
  which kustomize 2>&1 >/dev/null || download_kustomize
  echo "auto-complete: . <(kustomize completion bash)"
  . <(kustomize completion bash)
  kustomize version
  sleep 5
}

download_ocp_install() {
  DOWNLOAD_URL=https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-4.10/openshift-install-linux.tar.gz
  curl "${DOWNLOAD_URL}" -L | tar vzx -C ${TMP_DIR}/bin openshift-install
}

download_oc() {
  DOWNLOAD_URL=https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-4.10/openshift-client-linux.tar.gz
  curl "${DOWNLOAD_URL}" -L | tar vzx -C ${TMP_DIR}/bin oc
}

download_kustomize() {
  cd ${TMP_DIR}/bin
  curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
  cd ../..
}

create_id_rsa() {
  ssh-keygen -t rsa \
      -b 4096 \
      -P '' \
      -C Administrator@WINHOST \
      -f ${TMP_DIR}/id_rsa

}

win_init_ssh() {    
  [ -e ${TMP_DIR}/id_rsa ] || create_id_rsa

  oc --dry-run=client -o yaml \
    -n openshift-windows-machine-config-operator \
    create secret generic cloud-private-key \
    --from-file private-key.pem=generated/id_rsa \
    --from-file public-key.pem=generated/id_rsa.pub \
    > ${TMP_DIR}/cloud-private-key.yml
  
  oc apply -f ${TMP_DIR}/cloud-private-key.yml

}

win_init_install() {
    cd ${TMP_DIR}
    [ ! -d ${INSTALL_DIR} ] && mkdir ${INSTALL_DIR}
    cd ${INSTALL_DIR}
    
    [ -e install-config.yaml ] || openshift-install create install-config
    [ -e install-config.yaml ] || exit
}

win_update_sdn() {
  sed -i 's/OpenShiftSDN/OVNKubernetes/' install-config.yaml
  cp install-config.yaml ../install-config.yaml-$(date +%s)
}

win_create_manifests() {
  openshift-install create manifests
  [ ! -d manifests ] && mkdir manifests
}

win_create_vsphere_vxlan() {

echo "
apiVersion: operator.openshift.io/v1
kind: Network
metadata:
  name: cluster
spec:
  defaultNetwork:
    ovnKubernetesConfig:
      hybridOverlayConfig:
        hybridClusterNetwork:
          - cidr: 10.132.0.0/14
            hostPrefix: 23
        hybridOverlayVXLANPort: 9898
" > manifests/cluster-network-03-config.yaml

}

win_create_ovn_vxlan() {

echo "
apiVersion: operator.openshift.io/v1
kind: Network
metadata:
  name: cluster
spec:
  defaultNetwork:
    ovnKubernetesConfig:
      hybridOverlayConfig:
        hybridClusterNetwork:
          - cidr: 10.132.0.0/14
            hostPrefix: 23
" > manifests/cluster-network-03-config.yaml

}

win_install_wmco() {
  oc apply -k catalog/community-windows-machine-config-operator/operator/overlays/preview
}

ocp_backup_install() {
  cd ..
  [ ! -d install-$(date +%s) ] && cp -a ${INSTALL_DIR} install-$(date +%s)
}

ocp_print_cmd() {
  cd ..
  echo "${TMP_DIR}/bin/openshift-install create cluster --dir ${TMP_DIR}/${INSTALL_DIR}"
  echo "export KUBECONFIG=\$(pwd)/${TMP_DIR}/${INSTALL_DIR}/auth/kubeconfig"
  export KUBECONFIG=$(pwd)/${TMP_DIR}/${INSTALL_DIR}/auth/kubeconfig

  sleep 5
}

ocp_install_cmd() {
  cd ..
  ${TMP_DIR}/bin/openshift-install create cluster --dir ${TMP_DIR}/${INSTALL_DIR}
  export KUBECONFIG=$(pwd)/${TMP_DIR}/${INSTALL_DIR}/auth/kubeconfig
}

setup_bin
check_ocp_install
check_oc
check_kustomize

win_init_install
win_update_sdn
win_create_manifests
# win_create_ovn_vxlan
win_create_vsphere_vxlan

ocp_backup_install
ocp_print_cmd
ocp_install_cmd

win_install_wmco
win_init_ssh