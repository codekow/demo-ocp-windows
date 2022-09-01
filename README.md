# OpenShift 4.10+ (Windows) Install

This repository helps automate the install of OpenShift 4.10+
with Kubernetes OVN for use with Windows containers

Note: Running these scripts on a Linux workstation with internet access is assumed

## QuickStart
```
# pull this repo
git clone https://github.com/codekow/demo-ocp-windows.git
cd demo-ocp-windows

# setup vmware roles (optional)
. hacks/vsphere_roles.sh
vsphere_create_roles

# easy install button :)
hacks/install_ocp_win.sh

# run openshift-install
openshift-install create cluster --dir generated/ocp
```

## VMware Notes

Add vSphere folder path to `install-config.yml` at the following level in the yaml
```
platform:
  vsphere:
    
    # example folder path
    # folder: /${{ datacenter }}/vm/${{ folder path}}
    folder: /Central/vm/Sandbox/ocp4.tigerlab.io

    vcenter: 10.1.2.3
    ...
```

Assumption: Two vCenter Accounts
- Admin Account
- Installer Account (w/ roles assigned)

### Admin Account

`hacks/vsphere_roles.sh` is available to help automate the creation of vCenter roles with a vCenter administrator account.

### Installer Account

Assign the following roles to the vCenter account being used to install OpenShift at various levels in vCenter listed below.

### Precreated virtual machine folder in vSphere vCenter

Role Name | Propagate | Entity
--- | --- | ---
openshift-vcenter-level | False | vCenter
ReadOnly | False | Datacenter
openshift-cluster-level | True | Cluster
openshift-datastore-level | False | Datastore
ReadOnly | False | Switch
openshift-portgroup-level | False | Port Group
ReadOnly | True | Virtual Machine folder (Top Level)
openshift-folder-level | True | Virtual Machine folder

In a cascading (nested) folder organization you will need  "`Read-only`" permissions 
with "`Propagate to children`" from the top folder level.

Example Service Account: `OCPInstaller`

![Folder Tree Example](docs/folder-permissions.png)

## Machine Set - Windows

- Golden Image `unattend.xml`: [example-unattend.xml](example-unattend.xml)
- OCP MachineSet: [win-worker-machineset.yml](win-worker-machineset.yml)
```
kind: MachineSet
metadata:
  name: ocp4-win-worker
  namespace: openshift-machine-api
  labels:
    machine.openshift.io/cluster-api-cluster: ocp4-win
spec:
  replicas: 0
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-cluster: ocp4-win
      machine.openshift.io/cluster-api-machineset: ocp4-win-worker
  template:
    metadata:
      labels:
        machine.openshift.io/cluster-api-cluster: ocp4-win
        machine.openshift.io/cluster-api-machine-role: worker
        machine.openshift.io/cluster-api-machine-type: worker
        machine.openshift.io/cluster-api-machineset: ocp4-win-worker
        machine.openshift.io/os-id: Windows
    spec:
      metadata:
        labels:
          node-role.kubernetes.io/worker: ''
      providerSpec:
        value:
          userDataSecret:
            name: windows-user-data
          template: win2022
```

## Sample Windows Apps

- Basic Web App: [example-win-web.yml](example-win-web.yml)
- Win Daemon Set: [example-win-daemonset.yml](example-win-daemonset.yml)

## Links

OpenShift Docs
- [OpenShift 4.10 OVN Hybrid Networking](https://docs.openshift.com/container-platform/4.10/networking/ovn_kubernetes_network_provider/configuring-hybrid-networking.html)
- [vCenter Account Priviledges](https://docs.openshift.com/container-platform/4.10/installing/installing_vsphere/installing-vsphere-installer-provisioned.html#installation-vsphere-installer-infra-requirements_installing-vsphere-installer-provisioned)

Windows Machine Config Operator (WMCO)
- https://github.com/openshift/windows-machine-config-operator/blob/community-4.10/docs/setup-hybrid-OVNKubernetes-cluster.md
- https://github.com/openshift/windows-machine-config-operator/blob/community-4.10/README.md#configuring-byoh-bring-your-own-host-windows-instances
- https://github.com/openshift/windows-machine-config-operator/tree/community-4.10
- https://docs.openshift.com/container-platform/4.10/networking/ovn_kubernetes_network_provider/configuring-hybrid-networking.html
- https://docs.openshift.com/container-platform/4.10/windows_containers/creating_windows_machinesets/creating-windows-machineset-vsphere.html

Windows Images
- [Base Images - Windows](https://docs.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/container-base-images)
