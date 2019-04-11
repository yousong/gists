Use [hah](https://github.com/yousong/hah) instead

# TODO

- history of `IPV6_RECVPKTINFO`, `IPV6_PKTINFO`
- figure out why kernel stores into `msghdr.msg_name` an address of `::ffff:127.0.0.1` yet give an ipv4 address in `IP_PKTINFO` control message

	- https://groups.google.com/forum/#!topic/comp.os.linux.networking/9uVVSOgScqw

		Pascal Hambourg says
		> Bennett Haselton <ben...@peacefire.org> wrote:
		>> When I run "netstat" on my machine I get some lines like:
		> 
		>> tcp        0      0 ::ffff:69.72.177.140:80     ::ffff:<remote ip
		>> address>  TIME_WAIT
		> 
		> ::ffff is the IPv6 prefix for an IPv4 address mapped into IPv6 space
		> (something along those lines).
		And it means that it is an IPv6 socket that is used for IPv4
		communication. Application and socket-wise, it is IPv6 but network and
		packet-wise it is IPv4. This is allowed as a transition mechanism if
		net.ipv6.bindv6only=0 and the application didn't set the socket option
		IPV6_V6ONLY.

		It seems that some recent OSes disable this option by default so that
		IPv6 sockets can handle only real IPv6 communications.

	- https://stackoverflow.com/questions/1618240/how-to-support-both-ipv4-and-ipv6-connections

		The best approach is to create an IPv6 server socket that can also
		accept IPv4 connections. To do so, create a regular IPv6 socket,
		turn off the socket option IPV6_V6ONLY, bind it to the "any"
		address, and start receiving. IPv4 addresses will be presented as
		IPv6 addresses, in the IPv4-mapped format.
