package main

import (
	"fmt"
	"net"
	"os"
	"sync/atomic"
	"syscall"
)

type errType int

const (
	errTmo errType = iota
	errRst
	errRfd
	errOth
	errNUM
)

var errTypeStr = [...]string{
	"tmo",
	"rst",
	"rfd",
	"oth",
}

func checkErrType(err error) errType {
	var errno syscall.Errno
	if err1, ok := err.(*net.OpError); ok {
		err = err1.Err
	}
	if err1, ok := err.(*os.SyscallError); ok {
		err = err1.Err
	}
	if err1, ok := err.(syscall.Errno); ok {
		errno = err1
	}
	switch errno {
	case syscall.ETIMEDOUT:
		return errTmo
	case syscall.ECONNREFUSED:
		return errRfd
	case syscall.ECONNRESET:
		return errRst
	default:
		return errOth
	}
}

type stats struct {
	// server: total accepts, with or without errors
	// client: total connects, with or without errors
	total uint64
	// current connected
	current int64

	errors [errNUM]uint64
}

func (s *stats) incTotal() {
	atomic.AddUint64(&s.total, 1)
}

func (s *stats) incCurrent() {
	atomic.AddInt64(&s.current, 1)
}

func (s *stats) decCurrent() {
	atomic.AddInt64(&s.current, -1)
}

func (s *stats) incErr(err error) errType {
	ei := checkErrType(err)
	atomic.AddUint64(&s.errors[ei], 1)
	return ei
}

func (s *stats) String() string {
	r := ""
	r += fmt.Sprintf("total=%d", s.total)
	r += fmt.Sprintf(" current=%d", s.current)
	for ei := errType(0); ei < errNUM; ei++ {
		r += fmt.Sprintf(" %s=%d", errTypeStr[ei], s.errors[ei])
	}
	return r
}
