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
    def from_tuple(cls, ipport):
        sa = cls()
        sa.sa_family = ctypes.c_ushort(socket.AF_INET)
        sa.sin_addr = (ctypes.c_ubyte * 4)(*[int(i) for i in ipport[0].split('.')])
        sa.sin_port = ctypes.c_ushort(socket.htons(ipport[1]))
        return sa


def want_pktinfo(fd):
    _udpio.want_pktinfo(fd)


def recv_from_to(fd, buflen=4096, flags=0):
    buf = ctypes.create_string_buffer(buflen)
    from_addr = sockaddr_in()
    to_addr = sockaddr_in()
    addrlen = ctypes.c_int(ctypes.sizeof(from_addr))
    from_ = ctypes.byref(from_addr)
    to = ctypes.byref(to_addr)
    rv = _udpio.recv_from_to(fd, buf, buflen, flags, from_, to, addrlen)
    return rv, buf.value, from_addr.to_tuple(), to_addr.to_tuple()


def send_to_from(fd, data, to_tuple, from_tuple, flags=0):
    buf = ctypes.create_string_buffer(data)
    buflen = ctypes.c_int(len(buf))
    from_addr = sockaddr_in.from_tuple(from_tuple)
    to_addr = sockaddr_in.from_tuple(to_tuple)
    addrlen = ctypes.c_int(ctypes.sizeof(from_addr))
    from_ = ctypes.byref(from_addr)
    to = ctypes.byref(to_addr)
    rv = _udpio.send_to_from(fd, buf, buflen, flags, to, from_, addrlen)
    return rv
