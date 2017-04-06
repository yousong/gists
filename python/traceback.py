#!/usr/bin/env python
# - Internal types, https://docs.python.org/2/reference/datamodel.html#types
# - sys.exc_info(), https://docs.python.org/2/library/sys.html#sys.exc_info

import sys

def show_tb():
    tb = sys.exc_info()[2]
    print '>' * 5
    while True:
        if tb is None:
            break
        frame = tb.tb_frame
        lineno = tb.tb_lineno
        code = frame.f_code
        funcname = code.co_name
        filename = code.co_filename
        print '%s:%d: in function %s' % (filename, lineno, funcname)
        tb = tb.tb_next

def f():
    def g():
        def h():
            raise Exception('hello')
        def i():
            show_tb()
        try:
            h()
        except:
            i()
        i()
        raise Exception('world')
    g()

try:
    f()
except:
    show_tb()

