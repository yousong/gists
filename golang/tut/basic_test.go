package tut

import "testing"
import (
	"fmt"
)

func TestSliceElemNonPointer(t *testing.T) {
	type dummyT struct {
		mA int
	}
	v := dummyT{}
	s := []dummyT{v}
	v.mA = 1
	if v.mA == s[0].mA {
		t.Error("unexpected equal")
	}
}

func TestChanPointerType(t *testing.T) {
	c := make(chan int)
	d := c
	if c != d {
		t.Error("unexpected unequal")
	}
	go func() {
		c <- 2
	}()
	<-d
}

type T0 struct{ Name string }
type T1 struct{ T0 }

func (t1 *T0) Hello() string {
	return fmt.Sprintf("Hello %s from %s", t1.Name, "T0")
}
func (t1 *T1) Hello() string {
	return fmt.Sprintf("Hello %s from %s", t1.Name, "T1")
}
func TestFuncOverride(t *testing.T) {
	var t1 = &T1{}
	t1.Name = "value 1"
	t.Logf("%s", t1.Hello())
}

func TestNilSlice(t *testing.T) {
	var sli []int
	if len(sli) == 0 {
		t.Logf("nil slice has length 0")
	}
	for _, _ = range sli {
		t.Logf("nil slice can be ranged 0 times")
	}
	t.Logf("nil slice equals nil: %v", sli == nil)
}

func TestNilMap(t *testing.T) {
	var m map[string]int
	if len(m) == 0 {
		t.Logf("nil map has length 0")
	}
	for _, _ = range m {
		t.Logf("nil map can be ranged 0 times")
	}
	t.Logf("nil map equals nil: %v", m == nil)
}
