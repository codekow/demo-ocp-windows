# OpenShift Windows Machine Config Operator

Installs the OpenShift Windows Machine Config Operator (WMCO).

Do not use the `base` directory directly, as you will need to patch the `channel` and `version` based on the version of OpenShift you are using, or the version of the operator you want to use.

The current *overlays* available are for the following channels:
* [preview](overlays/preview)

