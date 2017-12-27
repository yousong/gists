#
# Useful links
#
#  - Extensions to the python2 sockets module that add 'recvmsg' and 'sendmsg',
#    https://github.com/metricube/PyXAPI
#  - PYTHON / CTYPES / SOCKET / DATAGRAM,
#    https://www.osso.nl/blog/python-ctypes-socket-datagram/
#
#    It's useful serving as reference guide or example code even though the
#    content is about sendto/recvfrom
#
#  - socket module of Python 3.3 has sendmsg, recvmsg support,
#    https://docs.python.org/3/library/socket.html#socket.socket.recvmsg
#
import ctypes
import socket
import os

try:
    _udpio = ctypes.cdll.LoadLibrary("_udpio.so")
except OSError:
    _udpio = ctypes.cdll.LoadLibrary("./_udpio.so")


class sockaddr_in(ctypes.Structure):
    _fields_ = [("sa_family", ctypes.c_ushort),  # sin_family
                ("sin_port", ctypes.c_ushort),
                ("sin_addr", ctypes.c_ubyte * 4),
                ("__pad", ctypes.c_ubyte * 8)]    # struct sockaddr_in is 16 bytes

    def to_tuple(self):
        return ("%d.%d.%d.%d" % tuple(self.sin_addr), socket.ntohs(self.sin_port))

    @classmethod
    def from_tuple(cls, ipport=None):
        sa = cls()
        sa.sa_family = ctypes.c_ushort(socket.AF_INET)
        if ipport is None:
            return sa
        sa.sin_addr = (ctypes.c_ubyte * 4)(*[int(i) for i in ipport[0].split('.')])
        sa.sin_port = ctypes.c_ushort(socket.htons(ipport[1]))
        return sa


class sockaddr_in6(ctypes.Structure):
    _fields_ = [("sa_family", ctypes.c_ushort),  # sin_family
                ("sin6_port", ctypes.c_ushort),
                ("sin6_flowinfo", ctypes.c_uint),
                ("sin6_addr", ctypes.c_ubyte * 16),
                ("sin6_scope_id", ctypes.c_uint),
                ("__pad", ctypes.c_ubyte * 4)]    # struct sockaddr_in6 is 32 bytes

    def to_tuple(self):
        if self.sa_family == socket.AF_INET6:
            ip_string = socket.inet_ntop(socket.AF_INET6, self.sin6_addr)
            if ip_string.startswith('::ffff:'):
                ip_string = ip_string[7:]
            port = socket.ntohs(self.sin6_port)
            return (ip_string, port)
        elif self.sa_family == socket.AF_INET:
            # This is possible in the following case
            #
            # We make a AF_INET6 socket that have IPV6_V6ONLY not set which
            # means it can also communicate with IPv4.  We use sockaddr_in6
            # because it's big enough to store either type of address from cmsg
            # PKTINFO
            sa = ctypes.cast(ctypes.pointer(self), ctypes.POINTER(sockaddr_in))
            sa = sa.contents
            return sa.to_tuple()
        else:
            raise Exception('unexpected af family: %s', self.sa_family)

    @classmethod
    def from_tuple(cls, ipport=None):
        if ipport is None:
            sa = cls()
            sa.sa_family = socket.AF_INET6
            return sa
        sa = None
        try:
            ip_string = ipport[0]
            ip_packed = socket.inet_pton(socket.AF_INET6, ip_string)
            sa = cls()
            sa.sa_family = ctypes.c_ushort(socket.AF_INET6)
            sa.sin6_addr = (ctypes.c_ubyte * 16)(*[ord(c) for c in ip_packed])
            sa.sin6_port = ctypes.c_ushort(socket.htons(ipport[1]))
        except socket.error:
            ip_string = ipport[0]
            ip_packed = socket.inet_pton(socket.AF_INET, ip_string)
            sa = sockaddr_in()
            sa.sa_family = ctypes.c_ushort(socket.AF_INET)
            sa.sin_addr = (ctypes.c_ubyte * 4)(*[ord(c) for c in ip_packed])
            sa.sin_port = ctypes.c_ushort(socket.htons(ipport[1]))
        return sa


def make_sockaddr(af, ipport=None):
    if af == socket.AF_INET:
        return sockaddr_in.from_tuple(ipport)
    elif af == socket.AF_INET6:
        return sockaddr_in6.from_tuple(ipport)
    else:
        raise Exception('unknown af type: %s', af)


def want_pktinfo(fd):
    _udpio.want_pktinfo(fd)


def recv_from_to(af, fd, buflen=4096, flags=0):
    buf = ctypes.create_string_buffer(buflen)
    from_addr = make_sockaddr(af)
    to_addr = make_sockaddr(af)
    addrlen = ctypes.c_int(ctypes.sizeof(from_addr))
    from_ = ctypes.byref(from_addr)
    to = ctypes.byref(to_addr)
    rv = _udpio.recv_from_to(fd, buf, buflen, flags, from_, to, addrlen)
    return rv, buf.value, from_addr.to_tuple(), to_addr.to_tuple()


def send_to_from(af, fd, data, to_tuple, from_tuple, flags=0):
    buf = ctypes.create_string_buffer(data)
    buflen = ctypes.c_int(len(buf))
    from_addr = make_sockaddr(af, from_tuple)
    to_addr = make_sockaddr(af, to_tuple)
    addrlen = ctypes.c_int(ctypes.sizeof(from_addr))
    from_ = ctypes.byref(from_addr)
    to = ctypes.byref(to_addr)
    rv = _udpio.send_to_from(fd, buf, buflen, flags, to, from_, addrlen)
    return rv
