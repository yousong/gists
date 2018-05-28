package tut

import "testing"
import (
	"unsafe"
)

type S struct{}

func TestZeroByteAlloc(t *testing.T) {
	// runtime.zerobase: base address for all 0-byte allocations.  See mallocgc() in runtime
	//
	// The empty struct, https://dave.cheney.net/2014/03/25/the-empty-struct
	var u, v S
	var w [0]int
	if unsafe.Sizeof(u) != 0 {
		t.Logf("sizeof empty struct should be zero: %d", unsafe.Sizeof(u))
	}
	if unsafe.Sizeof(w) != 0 {
		t.Logf("sizeof zero length array should be zero:  %d\n", unsafe.Sizeof(w))
	}
	var p0, p1 uintptr
	p0 = uintptr(unsafe.Pointer(&u))
	p1 = uintptr(unsafe.Pointer(&v))
	if p0 != p1 {
		t.Logf("address of 0-byte should be equal: %p, %p\n", &p0, &p1)
	}
	p1 = uintptr(unsafe.Pointer(&w))
	if p0 != p1 {
		t.Logf("address of 0-byte should be equal: %p, %p\n", &p0, &p1)
	}
	t.Logf("runzero.base: %x;  should be equal to the one from output of 'go tool nm'", p0)
}
