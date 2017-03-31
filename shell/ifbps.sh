#!/bin/sh
#
# netdev rate in bytes per second
#
netdev_bytes() {
  local ifname="$1"
  local column="$2"

  grep "^\s*$ifname:" /proc/net/dev | awk '{ print $'$column' }'
}

netdev_exists() {
  local ifname="$1"

  grep -q "^\s*$ifname:" /proc/net/dev
}

netdev_bytes_recv() {
  local ifname="$1"
  netdev_bytes "$ifname" 2
}

netdev_bytes_sent() {
  local ifname="$1"
  netdev_bytes "$ifname" 10
}

netdev_rate() {
  local ifname="$1"
  local prev_recv=0
  local prev_sent=0
  local curr_recv curr_sent

  if ! netdev_exists "$ifname"; then
	  echo "Cannot find netdev: $ifname" >&2
	  return 0;
  fi

  while true; do
    curr_recv="$(netdev_bytes_recv "$ifname")"
    curr_sent="$(netdev_bytes_sent "$ifname")"
    echo "$(($curr_recv - $prev_recv))  $(($curr_sent - $prev_sent))"
    sleep 1
    prev_recv="$curr_recv"
    prev_sent="$curr_sent"
  done
}

netdev_rate "$1"
