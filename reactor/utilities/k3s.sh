#
#=========================================================================================
# K3s Utilities
#

function kubernetes_status_k3s () {
  if [ "${APP_NAME:-}" ]; then
    if systemctl status k3s 1>/dev/null 2>&1; then
      return 0
    fi
  fi
  return 1
}

function start_kubernetes_k3s () {
  curl -sfL https://get.k3s.io 2>>"$(logfile)" | sh - 1>>"$(logfile)" 2>&1
  sudo cp -f /etc/rancher/k3s/k3s.yaml "$KUBECONFIG"
  sudo chown "${__user_name}:${__user_name}" "$KUBECONFIG"
  chmod 600 "$KUBECONFIG"
  sudo chmod 600 /etc/rancher/k3s/k3s.yaml

  if which nvidia-ctk >/dev/null; then
    info "Ensuring Nvidia GPU Docker support ..."
    sudo nvidia-ctk runtime configure --runtime=docker 1>>"$(logfile)" 2>&1
    sudo systemctl restart docker 1>>"$(logfile)" 2>&1

    info "Ensuring Nvidia GPU operator is installed ..."
    "${__bin_dir}/helm" repo add nvidia https://nvidia.github.io/gpu-operator 1>>"$(logfile)" 2>&1
    "${__bin_dir}/helm" repo update 1>>"$(logfile)" 2>&1
    "${__bin_dir}/helm" upgrade --install --wait --create-namespace -n nvidia-gpu gpu-operator nvidia/gpu-operator 1>>"$(logfile)" 2>&1
  fi
}

function provision_kubernetes_applications_k3s () {
  run_provisioner "${PROVISIONER_GATEWAY}" k3s_applications local
}

function destroy_kubernetes_applications_k3s () {
  if [ "${PROVISIONER_FORCE_DELETE_APPLICATIONS:-}" ]; then
    run_provisioner_delete "${PROVISIONER_GATEWAY}" k3s_applications local
  else
    run_provisioner_destroy "${PROVISIONER_GATEWAY}" k3s_applications local
  fi
}


function destroy_kubernetes_k3s () {
  info "Destroying K3s cluster service ..."
  if [ -x "/usr/local/bin/k3s-killall.sh" ]; then
    info "Killing all Kubernetes services ..."
    /usr/local/bin/k3s-killall.sh >>"$(logfile)" 2>&1
  fi
  info "Removing all Docker services ..."
  docker ps -a --filter name=k8s_ --format='{{ .ID }}' | xargs -P10 -I% docker rm -f % >>"$(logfile)" 2>&1
  docker system prune -f -a --volumes

  if [ -x "/usr/local/bin/k3s-uninstall.sh" ]; then
    info "Uninstalling the K3s Kubernetes service ..."
    /usr/local/bin/k3s-uninstall.sh 1>>"$(logfile)" 2>&1
  fi
}
