package tut

import "testing"
import (
	"sync/atomic"
	"unsafe"
)

func TestPointerAtomic(t *testing.T) {
	type S struct {
		wow string
	}
	var u = &S{wow: "hello"}

	var p unsafe.Pointer

	t.Logf("%s", (*S)(p))
	atomic.StorePointer(&p, unsafe.Pointer(u))
	t.Logf("%s", (*S)(p))
}
