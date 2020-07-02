package main

import (
	"io/ioutil"
	"strconv"
	"strings"

	"golang.org/x/sys/unix"

	"github.com/golang/glog"
)

func sysctlRead(p string) (string, error) {
	c, err := ioutil.ReadFile(p)
	if err != nil {
		return "", err
	}
	return string(c), nil
}

func getNofileSysMax() uint64 {
	max := uint64(unix.RLIM_INFINITY)

	if s, err := sysctlRead("/proc/sys/fs/nr_open"); err == nil {
		s = strings.TrimSpace(s)
		n, err := strconv.ParseUint(s, 10, 64)
		if err != nil {
			glog.Fatalf("bad fs.nr_open (%s): %v", s, err)
		}
		glog.Infof("fs.nr_open = %d", n)
		if max > n {
			max = n
		}
	}

	return max
}
