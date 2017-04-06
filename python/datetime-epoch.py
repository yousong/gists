#!/usr/bin/env python
# encoding: utf-8

import time
import re
from datetime import datetime

# https://docs.python.org/2/library/time.html
# https://docs.python.org/2/library/datetime.html

_s = (
    r'^'
    r'(?P<year>\d{4})年 (?P<month>\d\d)月 (?P<day>\d\d)日'
    r'.*'
    r'(?P<time>\d\d:\d\d:\d\d) CST'
    r'.*'
    r'time=(?P<delay>[\d.]+) ms'
    r'$'
)
RE_l = re.compile(_s)
line = '1970年 01月 01日 08:00:00 CST time=00.000 ms'
m = RE_l.match(line)
if m:
    dt = '{}-{}-{} {}'.format(
        m.group('year'),
        m.group('month'),
        m.group('day'),
        m.group('time'),
    )
    dt = datetime.strptime(dt, '%Y-%m-%d %H:%M:%S')
    dt = dt.timetuple()
    ts = time.mktime(dt)
    print ts
    dt = datetime.fromtimestamp(ts)
    print dt
    dt = time.localtime(ts)
    dt = datetime(*dt[:6])
    print dt
