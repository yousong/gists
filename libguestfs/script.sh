package_cleanup_leaves() {
	package-cleanup --leaves | tail -n+2 | xargs --no-run-if-empty rpm -e
}

package_cleanup_oldkernels() {
	package-cleanup -y --oldkernels --count 1
}

package_remove_networkmanager() {
	rpm -qa | sed -n '/NetworkManager-/p' | xargs --no-run-if-empty rpm -e
}

package_remove_firmwares() {
	rpm -qa | sed -n '/-firmware-/p' | xargs --no-run-if-empty rpm -e
}

package_install_wireguard() {
	local kversion
	local dkms_status

	yum-config-manager --add-repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo
	yum install --assumeyes wireguard-dkms wireguard-tools

	kversion="$(rpm -q kernel | sort --version-sort --reverse | head -n1 | cut -d- -f2-)"
	dkms_status="$(dkms status wireguard -k "$kversion" | sort --version-sort --reverse | head -n1)"

	if ! echo "$dkms_status" | grep -q installed; then
		dkms_version="$(echo "$dkms_status" | cut -d, -f2 | cut -d: -f1 | tr -c -d '0-9.\n')"
		dkms install -m wireguard -v "$dkms_version" -k "$kversion"
	fi
}

selinux_disable() {
	sed -i -e 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
}

sshd_usedns_no() {
	local f=/etc/ssh/sshd_config

	if grep -q '^#UseDNS yes$' "$f"; then
		sed -i -e 's/^#UseDNS yes$/UseDNS no/' "$f"
	else
		echo "UseDNS yes" >>"$f"
	fi
}

set -o xtrace
set -o errexit
set -o pipefail

selinux_disable
sshd_usedns_no
package_install_wireguard
package_remove_networkmanager
package_remove_firmwares
package_cleanup_oldkernels
package_cleanup_leaves
