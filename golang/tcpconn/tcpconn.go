package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"math/rand"
	"net"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"golang.org/x/sys/unix"

	"github.com/golang/glog"
)

var (
	argServe bool

	argAddr         string
	argPortRange    string
	argConnCount    int
	argConnDuration time.Duration
)

var (
	addr      net.IP
	portStart int
	portEnd   int

	errPortRange = errors.New("bad port range")
)

func init() {
	flag.BoolVar(&argServe, "s", false, "server or client (default client)")
	flag.StringVar(&argAddr, "addr", "127.0.0.1", "address to listen on or connect to")
	flag.StringVar(&argPortRange, "portrange", "20000-20100", "port range to serve or connect")
	flag.IntVar(&argConnCount, "count", 100, "number of connection to keep alive")
	flag.DurationVar(&argConnDuration, "duration", 7*time.Second, "duration to keep a connection")
}

type server struct {
}

func newServer() *server {
	return &server{}
}

func (s *server) start(ctx context.Context) {
	var listeners []net.Listener
	for p := portStart; p <= portEnd; p++ {
		listenAddr := net.JoinHostPort(
			addr.String(),
			strconv.FormatInt(int64(p), 10),
		)
		listener, err := net.Listen("tcp", listenAddr)
		if err != nil {
			glog.Errorln(err)
			continue
		}
		listeners = append(listeners, listener)
	}
	if len(listeners) == 0 {
		glog.Fatalf("no listener")
	}

	for _, listener := range listeners {
		go s.serveListener(listener)
	}
	<-ctx.Done()
}

func (s *server) serveListener(listener net.Listener) {
	defer listener.Close()
	for {
		conn, err := listener.Accept()
		if err != nil {
			glog.Warningf("accept %v", err)
			return
		}
		go s.serveListenerConn(conn)
	}
}

func (s *server) serveListenerConn(conn net.Conn) {
	defer conn.Close()

	buf := make([]byte, 1024)
	for {
		n, err := conn.Read(buf)
		if err != nil {
			if err != io.EOF {
				glog.Warningf("conn.read %v", err)
			}
			return
		}
		if n > 0 {
			conn.Write(buf[:n])
		}
	}
}

type client struct {
	conns    []net.Conn
	pendings int
	mu       *sync.Mutex

	cond   *sync.Cond
	connCh chan net.Conn

	fails int32
}

func newClient() *client {
	client := &client{
		mu: &sync.Mutex{},
		cond: sync.NewCond(
			&sync.Mutex{},
		),
		connCh: make(chan net.Conn),
	}
	return client
}

func (c *client) start(ctx context.Context) {
	go c.addConns()
	go c.report()
	for {
		c.cond.L.Lock()
		for {
			c.mu.Lock()
			fails := atomic.LoadInt32(&c.fails)
			if (fails < 3 && len(c.conns)+c.pendings < argConnCount) ||
				(fails >= 3 && c.pendings == 0) {
				c.mu.Unlock()
				break
			}
			c.mu.Unlock()
			c.cond.Wait()
		}
		c.cond.L.Unlock()

		c.mu.Lock()
		c.pendings += 1
		c.mu.Unlock()
		if atomic.LoadInt32(&c.fails) >= 3 {
			<-time.NewTimer(time.Second).C
		}
		go c.connectOne()
	}
}

func (c *client) report() {
	p := func() {
		c.mu.Lock()
		curr, pending := len(c.conns), c.pendings
		c.mu.Unlock()
		glog.Infof("current %d, pending %d", curr, pending)
	}
	tick := time.NewTicker(2 * time.Second)

	p()
	for {
		select {
		case <-tick.C:
			p()
		}
	}
}

func (c *client) addConns() {
	for {
		conn := <-c.connCh
		c.mu.Lock()
		c.pendings -= 1
		if conn != nil {
			c.conns = append(c.conns, conn)
			go c.connectWork(conn)
		}
		c.mu.Unlock()
		c.cond.Signal()
	}
}

func (c *client) removeConn(conn net.Conn) {
	c.mu.Lock()
	defer c.mu.Unlock()
	for i, old := range c.conns {
		if old == conn {
			copy(c.conns[i:], c.conns[i+1:])
			c.conns = c.conns[:len(c.conns)-1]
			c.cond.Signal()
			return
		}
	}
}

func (c *client) connectOne() {
	connPort := portStart + rand.Intn(portEnd-portStart+1)
	connAddr := net.JoinHostPort(addr.String(), strconv.FormatInt(int64(connPort), 10))
	conn, err := net.DialTimeout("tcp", connAddr, 3*time.Second)
	if err != nil {
		glog.Errorf("%v", err)
		atomic.AddInt32(&c.fails, 1)
	} else {
		atomic.StoreInt32(&c.fails, 0)
	}
	c.connCh <- conn
}

func (c *client) connectWork(conn net.Conn) {
	defer func() {
		conn.Close()
		c.removeConn(conn)
	}()

	hey := []byte("hey")
	interval := 3 * time.Second
	stime := time.Now()
	for {
		var err error
		_, err = conn.Write(hey)
		if err != nil {
			if err != io.EOF {
				glog.Errorf("write %v", err)
			}
			return
		}
		_, err = conn.Read(hey)
		if err != nil {
			if err != io.EOF {
				glog.Errorf("read %v", err)
			}
			return
		}
		if time.Since(stime)+interval > argConnDuration {
			// remove
			return
		}
		time.Sleep(interval)
	}
}

func parsePortRange(s string) (start, end int, err error) {
	parts := strings.SplitN(s, "-", 2)
	if len(parts) != 2 {
		err = fmt.Errorf("%w: want 2 parts, got %d", errPortRange, len(parts))
		return
	}
	ports := make([]int, 2)
	for i, part := range parts {
		part = strings.TrimSpace(part)
		var p int64
		p, err = strconv.ParseInt(part, 10, 16)
		if err != nil {
			err = fmt.Errorf("%s: %w", errPortRange, err)
			return
		}
		if p <= 0 || p > 65535 {
			err = fmt.Errorf("%w: bad transport port %s", errPortRange, part)
			return
		}
		ports[i] = int(p)
	}
	start = ports[0]
	end = ports[1]
	if start > end {
		err = fmt.Errorf("%w: start > end", errPortRange)
		return
	}
	return
}

func setRlimit() {
	rlim := &unix.Rlimit{}
	if err := unix.Getrlimit(unix.RLIMIT_NOFILE, rlim); err != nil {
		glog.Errorf("getrlimit %v", err)
		return
	}
	var (
		cur       = rlim.Cur
		curMax    = rlim.Max
		curMaxSys = getNofileSysMax()
	)

	for _, val := range []uint64{
		curMaxSys, // requires CAP_SYS_RESOURCE
		curMax,
	} {
		if val == cur {
			continue
		}
		rlim.Cur = val
		rlim.Max = val
		if err := unix.Setrlimit(unix.RLIMIT_NOFILE, rlim); err != nil {
			glog.Errorf("setrlimit(RLIMIT_NOFILE, %d): %v", val, err)
		} else {
			glog.Infof("RLIMIT_NOFILE set to %d", val)
			break
		}
	}
}

func main() {
	flag.Parse()
	flag.Lookup("logtostderr").Value.Set("true")

	{
		var err error
		addr = net.ParseIP(argAddr)
		if addr == nil {
			glog.Fatalf("bad addr: %s", argAddr)
		}
		portStart, portEnd, err = parsePortRange(argPortRange)
		if err != nil {
			glog.Fatalln(err)
		}
	}

	ctx := context.Background()
	ctx, cancelFunc := context.WithCancel(ctx)

	go func() {
		sigCh := make(chan os.Signal)
		signal.Notify(sigCh,
			unix.SIGINT,
			unix.SIGTERM,
		)
		select {
		case sig := <-sigCh:
			glog.Infof("received signal %s", sig)
			cancelFunc()
		}
	}()

	setRlimit()
	if argServe {
		s := newServer()
		go s.start(ctx)
	} else {
		c := newClient()
		go c.start(ctx)
	}

	select {
	case <-ctx.Done():
		glog.Infof("bye")
	}
}
