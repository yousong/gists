package main

import (
	"fmt"
	"syscall"
)

func main() {
	// package syscall is locked down.  golang.org/x/sys should be used when
	// possible.
	//
	//
	// CentOS do no have CLONE_NEWUSER out of the box.  See
	// https://github.com/yousong/build-scripts/commit/897376a27871cf1955ca487a76ac2f9976e29500
	// for more details
	procAttr := syscall.ProcAttr{
		Sys: &syscall.SysProcAttr{
			Cloneflags: syscall.CLONE_NEWUSER,
		},
	}
	if pid, err := syscall.ForkExec("/bin/true", []string{"arg0"}, &procAttr); err != nil {
		fmt.Printf("ForkExec: pid: %d, err: %d (%s)\n", pid, err, err)
	} else {
		var wstatus syscall.WaitStatus
		if wpid, err := syscall.Wait4(pid, &wstatus, 0, nil); err != nil {
			fmt.Printf("Wait4: pid: %d, err: %d(%s)\n", pid, err, err)
		} else {
			fmt.Printf("pid: %d, wpid: %d, exitcode: %d\n", pid, wpid, wstatus.ExitStatus())
		}
	}
}
