package main

import "testing"
import (
	"strings"
)

func TestSplit(t *testing.T) {
	segs := []string{"", "ips", "uuid-ip", "nics", "uuid-nic"}
	url := strings.Join(segs, "/")
	segs1 := strings.Split(url, "/")
	if len(segs) != len(segs1) {
		t.Fatalf("segs length: %d!=%d", len(segs), len(segs1))
	}
	for i, seg := range segs {
		if seg != segs1[i] {
			t.Fatalf("seg not equal: %d: %s!=%s", i, seg, segs1[i])
		}
	}
}
