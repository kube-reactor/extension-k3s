#
#=========================================================================================
# Initialization
#
#
# Project Directories
#
export __k3s_extension_dir="${2}"

if [ "${KUBERNETES_PROVIDER:-}" == "k3s" ]; then
  export INSTALL_K3S_EXEC="server --docker --disable=coredns --disable=metrics-server --disable=traefik"
fi
