# Try kubespray

 - https://github.com/kubernetes-sigs/kubespray

# TODO

 - multi-master cluster
   - https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/
   - https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/
 - drain and take down

Kube-proxy IPVS mode

 - https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/#config-file
 - role variable: kubernetes_kubeadm_init_extra_opt

Network other than flannel, e.g. calico

 - https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#pod-network

# tips

	kubeadm config images list
	kubeadm config images pull --help

	# useful on version bump, re-run kubeadm init
	rm -vf /etc/kubernetes/admin.conf
