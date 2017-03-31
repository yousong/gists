// Copyright (c) Yousong Zhou
//
// tcp simultaneous open
//
//		Flags [S], ..., length 0
//		Flags [S], ..., length 0
//		Flags [S.], ..., length 0
//		Flags [S.], ..., length 0
//		Flags [.], ..., length 0
//		Flags [.], ..., length 0
//
// The connection may come across RST,ACK if SYN arrived before the bind call.
// In this case, the following netem rule may help, http://stackoverflow.com/questions/2231283/tcp-two-sides-trying-to-connect-simultaneously
//
//		sudo tc qdisc add dev lo root handle 1:0 netem delay 10ms
//		sudo tc qdisc del dev lo root handle 1:0 netem delay 10ms
//
// Or use the following iptables rule to drop rst,ack packet
//
//		sudo iptables -A OUTPUT -o lo -p tcp --tcp-flags RST,ACK RST,ACK -j DROP
//		sudo iptables -D OUTPUT -o lo -p tcp --tcp-flags RST,ACK RST,ACK -j DROP
//
package main

import (
	"flag"
	"fmt"
	"net"
	"os"
	"sync"
)

var wg sync.WaitGroup

func conn(laddr, raddr *net.TCPAddr) {
	defer wg.Done()

	conn, err := net.DialTCP("tcp4", laddr, raddr)
	if err == nil {
		defer conn.Close()
		fmt.Fprintf(conn, "hello %s, i am %s\n", raddr, laddr)
		b := make([]byte, 128)
		_, err := conn.Read(b)
		if err == nil {
			fmt.Print(string(b))
		} else {
			fmt.Fprintf(os.Stderr, "%s\n", err)
		}
	} else {
		fmt.Fprintf(os.Stderr, "%s\n", err)
	}
}

func main() {
	var laddr = &net.TCPAddr{
		IP: net.IP{127, 0, 0, 1},
	}
	var raddr = &net.TCPAddr{
		IP: net.IP{127, 0, 0, 1},
	}

	flag.IntVar(&laddr.Port, "lport", 1077, "local port")
	flag.IntVar(&raddr.Port, "rport", 1078, "remote port")
	flag.Parse()

	wg.Add(2)
	go conn(laddr, raddr)
	go conn(raddr, laddr)
	wg.Wait()
}
