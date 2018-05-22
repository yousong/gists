package main

import "testing"

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
