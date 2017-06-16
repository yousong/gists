#!/usr/bin/env python
import logging
import time
import json
import socket

from tornado.ioloop import IOLoop
from tornado.tcpserver import TCPServer
from tornado.httpserver import HTTPServer
from tornado.web import RequestHandler, Application
from tornado.web import MissingArgumentError
from tornado.options import define, options

# How to use this
#
#   python echoserver.py --http=6000,6001 --tcp=7000,7001 --udp=9002
#
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class StreamHandler(object):
    def __init__(self, stream):
        self.stream = stream

        ts = time.time()
        sock = stream.socket
        localip, localport = sock.getsockname()
        remoteip, remoteport = sock.getpeername()
        self.info = {
            'ts': ts,
            'localip': localip,
            'localport': localport,
            'remoteip': remoteip,
            'remoteport': remoteport,
        }

    def get_stream_info(self):
        return self.info

    def log(self):
        info = self.get_stream_info()
        localip, localport = info['localip'], info['localport']
        remoteip, remoteport = info['remoteip'], info['remoteport']
        logger.info('tcp from %s:%s -> %s:%s', remoteip, remoteport, localip, localport)

    def wait_and_respond(self):
        self.stream.read_until('\n', callback=self._receive_done)

    def _receive_done(self, data):
        data = data[:-1]
        info = self.get_stream_info()
        resp = {'data': data}
        resp.update(info)
        resp = json.dumps(resp)
        resp += '\n'
        self.stream.write(resp)
        self.wait_and_respond()


class EchoTCPServer(TCPServer):
    def handle_stream(self, stream, address):
        sh = StreamHandler(stream)
        sh.log()
        sh.wait_and_respond()


class EchoUDPServer(object):
    def __init__(self, ioloop=None):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.setblocking(False)
        self.fd = self.sock.fileno()
        if ioloop is None:
            ioloop = IOLoop.current()
        self.ioloop = ioloop

    def listen(self, port, address='', ioloop=None):
        self.sock.bind((address, port))
        #self.sock.listen(128)
        self.ioloop.add_handler(self.fd, self.handle_message, IOLoop.READ | IOLoop.ERROR)

    def handle_message(self, fd, events):
        if events & IOLoop.READ:
            ts = time.time()
            localip, localport = self.sock.getsockname()
            data, remoteaddr = self.sock.recvfrom(4096)
            remoteip, remoteport = remoteaddr
            resp = {
                'ts': ts,
                'data': data,
                'localip': localip,
                'localport': localport,
                'remoteip': remoteip,
                'remoteport': remoteport,
            }
            resp = json.dumps(resp)
            resp += '\n'
            self.sock.sendto(resp, remoteaddr)
            logger.info('udp from %s:%s -> %s:%s', remoteip, remoteport, localip, localport)
        elif events & IOLoop.ERROR:
            logger.error('udp %s event error', self.sock.getsockname())
            self.sock.close()
            self.ioloop.remove_handler(self.fd)
        else:
            pass


class EchoRequestHandler(RequestHandler):
    def head(self, *args, **kwargs):
        pass

    def get(self, *args, **kwargs):
        sh = StreamHandler(self.request.connection.stream)
        info = sh.get_stream_info()
        resp = {}
        resp.update(info)
        try:
            data = self.get_query_argument('data')
        except MissingArgumentError:
            data = None
        resp['data'] = data
        # peerip can be different from remoteip by taking value from
        # X-Forwarded-For or X-Real-IP
        resp['peerip'] = self.request.remote_ip
        resp = json.dumps(resp)
        resp += '\n'
        self.write(resp)


def init_options():
    define('http', type=int, multiple=True, help='ports to serve HTTP')
    define('tcp', type=int, multiple=True, help='ports to serve TCP')
    define('udp', type=int, multiple=True, help='ports to serve UDP')


def main():
    init_options()
    options.parse_command_line()

    tcpservers = []
    udpservers = []
    httpservers = []

    for port in options.tcp:
        tcpserver = EchoTCPServer()
        tcpserver.listen(port)
        tcpservers.append(tcpserver)

    for port in options.udp:
        udpserver = EchoUDPServer()
        udpserver.listen(port)
        udpservers.append(udpserver)

    if len(options.http) > 0:
        app = Application([
            (r'/', EchoRequestHandler),
        ])
        for port in options.http:
            httpserver = HTTPServer(app)
            httpserver.listen(port)
            httpservers.append(httpserver)

    if len(httpservers) != 0 \
            or len(tcpservers) != 0 \
            or len(udpservers) != 0:
        try:
            IOLoop.current().start()
        except KeyboardInterrupt:
            pass
    else:
        logger.warning('no http, tcp, or udp port to serve')
    logger.info('bye')

if __name__ == '__main__':
    main()
