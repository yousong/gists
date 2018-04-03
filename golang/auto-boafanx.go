package main

import (
	"fmt"
	"log"
	"os"
	"runtime"
	"strings"
	"regexp"
	"io"
	"io/ioutil"
	"net/http"
	"os/exec"
	"os/signal"
)

type SSHAccount struct {
	host, port string
	user, pass string
}

func boafanxSSH(c chan SSHAccount) {

	/* Example string to match
<pre><code>SSH服务器：69.85.84.151
SSH账号：boafanx2
SSH密码：ff
SSH端口：1232
本地端口：7070
	*/
	reInfoBlock := regexp.MustCompile("(?s)<code>(.{16,}?)</code>")
	reHost := regexp.MustCompile("SSH服务器：([^\n]+)")
	rePort := regexp.MustCompile("SSH端口：([\\d]+)")
	reUser := regexp.MustCompile("SSH账号：([^\n]+)")
	rePass := regexp.MustCompile("SSH密码：([^\n]+)")
	for {
		resp, err := http.Get("http://boafanx.tabboa.com/free/")
		if err != nil {
			log.Println(err)
			continue
		}
		body_byte, err := ioutil.ReadAll(resp.Body)
		resp.Body.Close()
		if err != nil {
			log.Println(err)
		}
		body_str := string(body_byte)
		//fmt.Print(body_str)
		m := reInfoBlock.FindAllStringSubmatch(body_str, -1)
		for i := range m {
			s := m[i][1]
			host := reHost.FindStringSubmatch(s)
			port := rePort.FindStringSubmatch(s)
			user := reUser.FindStringSubmatch(s)
			pass := rePass.FindStringSubmatch(s)
			if len(host) + len(port) + len(user) + len(pass) < 8 {
				log.Println(fmt.Sprintf("Incomplete info in block: %s", s));
				continue
			}
			_host := strings.TrimSpace(host[1])
			_port := strings.TrimSpace(port[1])
			_user := strings.TrimSpace(user[1])
			_pass := strings.TrimSpace(pass[1])
			sa := SSHAccount{host:_host, port:_port, user:_user, pass:_pass}
			c <- sa
		}
	}
}

var sshArgs []string
func TunnelKeeper(c chan SSHAccount) {
	sigchan := make(chan os.Signal)
	errchan := make(chan error)
	signal.Notify(sigchan, os.Interrupt)
	sa := <- c
	for {
		var cmd exec.Cmd
		if runtime.GOOS == "windows" {
			cmd.Path, _ = exec.LookPath("plink.exe")
			cmd.Args = []string{cmd.Path, "-C", "-v", "-noagent", "-N", "-D", "7001", "-P", sa.port, "-pw", sa.pass, fmt.Sprintf("%s@%s", sa.user, sa.host)}
		} else if runtime.GOOS == "linux" {
			cmd.Path, _ = exec.LookPath("ssh")
			cmd.Args = []string{cmd.Path, "-C", "-v", "-N", "-D", "7001", "-p", sa.port, fmt.Sprintf("%s@%s", sa.user, sa.host)}
		} else {
			log.Fatal(fmt.Sprintf("Not supported OS: %s\n", runtime.GOOS))
			os.Exit(1)
		}
		log.Println(strings.Join(cmd.Args, " "))
		stdin, _ := cmd.StdinPipe()
		stdout, _ := cmd.StdoutPipe()
		stderr, _ := cmd.StderrPipe()
		go io.Copy(stdin, os.Stdin)
		go io.Copy(os.Stdout, stdout)
		go io.Copy(os.Stderr, stderr)
		cmd.Start()
		go func() {
			errchan <- cmd.Wait()
		}()
		var err error
		select {
			case <-sigchan:
				if err = cmd.Process.Kill(); err != nil {
					log.Println(fmt.Sprintf("Kill failed: %s", err))
				}
				err = <-errchan
			case err = <-errchan:
		}
		if err != nil {
			log.Println(fmt.Sprintf("Process quit: %s", err))
		}
		sa = <-c
	}
}

func main() {
	c := make(chan SSHAccount)
	go boafanxSSH(c)
	go TunnelKeeper(c)
	select {}
}
