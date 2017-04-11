#
# Variables
#
#	iplist		IP addresses that will be used as source addresses in probes
#	ipsshlist	IP addresses for
#				- ssh login
#				- ssh remote cmd
#				- bulk transfer with scp
#	pingips		IP addresses to be probed
#
#	user		username for login
#	idrsa		ssh identity keyfile for login
#	workdir		where to put scripts and do the probe
#
# iplist and ipsshlist can be different if the probing machines each have at
# least 2 ip addresses.  One group of them is used as default route for
# outgoing traffic and the other for internal communication such as bulk data
# transfer.  Isolating result data transfer and actual probing traffic can help
# reduce interferences.
#
# Before running any serious test, you may want to make sure all hosts involved
# have a synchronized wall time
#
#	./msh.sh m_gettime
#	./msh.sh m_synctime
#
# How it works
#
#	./msh.sh m_reset
#
#		0. login to each machine
#		1. rm -rf $workdir
#		2. mkdir -p $workdir
#		2. scp scr-xxx.sh to $workdir
#
#	./msh.sh m_ping <ip>
#
#		0. login to each machine
#		1. run "scr-ping.sh <ip>" there
#
#	./msh.sh m_trace <ip>
#
#		0. login to each machine
#		1. run "scr-trace.sh <ip>" there
#
#	./msh.sh m_kill
#
#		0. login to each machine
#		1. kill all scr-xxx.sh processes
#
#	./m.sh fetch
#
#		0. scp ping results from each machine
#		1. scp a tracepath result
#
#	./m.sh fmt
#
#		0. fmt ping results
#
#	./m.sh gnuplot
#
#		0. do "gnuplot ping.plot"
#
# How to make it work
#
# 0. Prepare ip.list, ip.ssh.list, ip.ping.list.  ip.list and ip.ssh.list
#    should have a one-to-one mapping to each other
# 1. Make sure unattended login to $ipsshlist is working
# 2. Edit ping.gnuplot for a proper multiplot layout
#
iplist="$(cat ip.list)"
ipsshlist="$(cat ip.ssh.list)"
pingips="$(cat ip.ping.list)"

user=root
idrsa=root.id_rsa
workdir=/root/trace
