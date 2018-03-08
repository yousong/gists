package main

import (
	"bytes"
	"fmt"
	"net"
	"time"
)

func tPipe() {
	// synchronous, in-memory, full-duplex net.Conn
	client, server := net.Pipe()
	bufW := []byte("hello")
	bufR := make([]byte, len(bufW))
	donec := make(chan struct{})
	deadline := time.Now().Add(1 * time.Second)
	client.SetDeadline(deadline)
	server.SetDeadline(deadline)
	go func() {
		if n, err := server.Read(bufR); err != nil {
			fmt.Printf("server read: error: %s\n", err)
		} else if bytes.Equal(bufR, bufW) {
			fmt.Printf("server read: nbytes: %d\n", n)
		} else {
			fmt.Printf("server read: error match: %s, %s\n", bufR, bufW)
		}
		close(donec)
	}()
	time.Sleep(2 * time.Second)
	if n, err := client.Write(bufW); err != nil {
		fmt.Printf("client write: error: %s\n", err)
	} else {
		fmt.Printf("client write: nbytes: %d\n", n)
	}
	<-donec
}

func main() {
	tPipe()
}
