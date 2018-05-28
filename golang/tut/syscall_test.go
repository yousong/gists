package tut

// package syscall is locked down.  golang.org/x/sys should be used when
// possible.

import "testing"
import (
	"github.com/shirou/gopsutil/host"
	"syscall"
)

func TestCloneNewUser(t *testing.T) {
	// CentOS do no have CLONE_NEWUSER out of the box.  See
	// https://github.com/yousong/build-scripts/commit/897376a27871cf1955ca487a76ac2f9976e29500
	// for more details
	if _, family, _, err := host.PlatformInformation(); err != nil {
		t.Errorf("error finding host platform info: %s", err)
	} else if family == "rhel" {
		t.Skipf("skip test for rhel family systems")
	}

	procAttr := syscall.ProcAttr{
		Sys: &syscall.SysProcAttr{
			Cloneflags: syscall.CLONE_NEWUSER,
		},
	}
	pid, err := syscall.ForkExec("/bin/true", []string{"arg0"}, &procAttr)
	if err != nil {
		t.Fatalf("ForkExec error: %d (%s)", err, err)
	}

	var wstatus syscall.WaitStatus
	wpid, err := syscall.Wait4(pid, &wstatus, 0, nil)
	if err != nil {
		t.Fatalf("Wait error: %d(%s)", err, err)
	}
	if wpid != pid {
		t.Fatalf("wpid != pid: %d!=%d", wpid, pid)
	}
	if wstatus.ExitStatus() != 0 {
		t.Fatalf("exit status: %d", wstatus.ExitStatus())
	}
}
