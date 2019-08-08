#!/bin/sh

# Configuration
#
#	LoadPlugin threshold
#	<Plugin threshold>
#	  <Plugin "ping">
#	    <Type "ping_droprate">
#	      FailureMax 0.95
#	      Hits 1
#	    </Type>
#	  </Plugin>
#	</Plugin>
#
#	LoadPlugin exec
#	<Plugin exec>
#	  NotificationExec root "/root/collectd-notify.sh"
#	</Plugin>
#

__newline="
"
parse_notification() {
	local line
	local state=hdr

	while read line; do
		if [ "$state" = "hdr" ]; then
			if [ -n "$line" ]; then
				eval "collectd_${line/: /=}"
				collectd_headers="$collectd_headers ${line%%: *}"
			else
				state="body"
			fi
		else
			collectd_body="$collectd_body$__newline$line"
		fi
	done
}

test_parse_notification() {
	local hdr

	parse_notification <<-"EOF"
		Severity: FAILURE
		Time: 1565245768.065
		Host: xxx
		Plugin: ping
		Type: ping_droprate
		TypeInstance: 8.8.8.8
		DataSource: value
		CurrentValue: 1.000000e+00
		WarningMin: nan
		WarningMax: nan
		FailureMin: nan
		FailureMax: 1.000000e-05

		Host xxx, plugin ping type ping_droprate (instance 8.8.8.8): Data source "value" is currently 1.000000. That is above the failure threshold of 0.000010.
		NEWLINE
	EOF
	for hdr in $collectd_headers; do
		eval "echo $hdr: \$collectd_$hdr"
	done
	echo "$collectd_body"
}

log() {
	logger -t "collectd-notify" "$@"
}

if [ "$1" = test ]; then
	test_parse_notification
	exit 0
fi

parse_notification

restart_wg0() {
	case "$collectd_Host" in
		xxx*)
			sudo systemctl restart wg-quick@wg0
			;;
		OpenWrt*)
			ifup wg0
			;;
		*)
			log "unknown host: $collectd_Host"
	esac
}

if [ "$collectd_TypeInstance" = "8.8.8.8" ]; then
	log "$collectd_body"
	if [ "$collectd_Severity" = "FAILURE" ]; then
		restart_wg0
	fi
fi
