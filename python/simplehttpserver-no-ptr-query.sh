python -c "import socket as s; s.getfqdn=lambda x:x; import sys; sys.argv.append('18080'); import SimpleHTTPServer as u; u.test()"
python -c "import socket as s; s.getfqdn=lambda x:x; import sys; sys.argv.append('13306'); import SimpleHTTPServer as u; u.test()"
