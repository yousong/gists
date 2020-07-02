package main

import (
	"golang.org/x/sys/unix"

	"github.com/golang/glog"
)

// man 2 setrlimit
//
//  > setrlimit() now returns with errno set to EINVAL in places that histori-cally
//  > historically cally succeeded.  It no longer accepts "rlim_cur = RLIM_INFINITY"
//  > for RLIM_NOFILE.  Use "rlim_cur = min(OPEN_MAX, rlim_max)".
//
// Appeared also in Go runtime TestRlimit
//
const OPEN_MAX = 10240 // /usr/include/sys/syslimits.h

func getNofileSysMax() uint64 {
	max := uint64(unix.RLIM_INFINITY)

	if max > OPEN_MAX {
		max = OPEN_MAX
	}

	sysctls := [...]string{
		"kern.maxfilesperproc",
		"kern.maxfiles",
		"kern.num_files",
	}
	nums := make([]uint64, len(sysctls))
	for i, sysctl := range sysctls {
		n, err := unix.SysctlUint32(sysctl)
		if err != nil {
			glog.Warningf("sysctl %s: %v", sysctl, err)
			continue
		}
		nums[i] = uint64(n)
		glog.Infof("%s = %d", sysctl, n)
	}

	if mfpp := nums[0]; mfpp > 0 && max > mfpp {
		max = uint64(mfpp)
	}
	return max
}
