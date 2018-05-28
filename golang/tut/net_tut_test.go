package tut

import "testing"
import (
	"bytes"
	"net"
	"time"
)

func TestPipe(t *testing.T) {
	// synchronous, in-memory, full-duplex net.Conn
	client, server := net.Pipe()
	bufW := []byte("hello")
	bufR := make([]byte, len(bufW))
	donec := make(chan struct{})
	deadline := time.Now().Add(1 * time.Second)
	client.SetDeadline(deadline)
	server.SetDeadline(deadline)
	go func() {
		if _, err := server.Read(bufR); err != nil {
			t.Fatalf("server read error: %s", err)
		}
		if !bytes.Equal(bufR, bufW) {
			t.Logf("  expecting: %v", bufW)
			t.Logf("  got: %v", bufR)
			t.Fatalf("server read not equal")
		}
		close(donec)
	}()
	// NOTE: this will cause deadline error
	//time.Sleep(2 * time.Second)
	if n, err := client.Write(bufW); err != nil {
		t.Fatalf("client write error: %s", err)
	} else if n != len(bufR) {
		t.Fatalf("client write %d, expecting %d", n, len(bufW))
	}
	<-donec
}
