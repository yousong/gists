#!/usr/bin/env python2
import json
import glob
import ctypes
import DictionaryServices

import sys
reload(sys)
sys.setdefaultencoding('utf8')

# https://github.com/adambom/dictionary
with open('d.json', 'rb') as fin:
    d = json.load(fin)

def conv_json(w):
    W = w.upper()
    if W in d:
        wdef = d[W].encode('utf8')
    else:
        wdef = ''
    return wdef

def conv_core(w):
    s_dict = None
    try:
        w += ' '
        s_range = DictionaryServices.DCSGetTermRangeInString(s_dict, w, 0)
        s_definition = DictionaryServices.DCSCopyTextDefinition(s_dict, w, s_range)
        wdef = s_definition
    except Exception as e:
        wdef = ''
    return wdef

lu = ctypes.cdll.LoadLibrary('lookup.dylib')
lu.lookup.argtypes = [ctypes.c_char_p]
lu.lookup.restype = ctypes.c_void_p
lu.lookup_free.argtypes = [ctypes.c_void_p]
lu.lookup_free.restype = None
def conv_lookup(w):
    wdefp = lu.lookup(w)
    if wdefp:
        wdef = ctypes.cast(wdefp, ctypes.c_char_p)
        wdef = wdef.value
        lu.lookup_free(wdefp)
        if '\n' in wdef:
            wdef = wdef.rstrip().split('\n')
            wdef = ' | '.join(wdef)
        return wdef
    else:
        return ''

def conv_comb(w):
    for f in (conv_lookup, conv_json):
        wdef = f(w)
        if wdef:
            return wdef
    sys.stderr.write('# ' + w + '\n')
    return ''

def drv_conv(inf, outf, conv_func=None):
    assert(conv_func is not None)

    with open(outf, 'wb') as foutf:
        with open(inf, 'rb') as finf:
            for w in finf:
                w = w.strip()
                wdef = conv_func(w)
                foutf.write(w + '\t' + wdef + '\n')

def drv(conv_func=conv_lookup):
    flist = glob.glob('????.txt')
    for inf in flist:
        outf = 'economist.words.' + inf
        drv_conv(inf, outf, conv_func=conv_func)

if __name__ == '__main__':
    drv(conv_func=conv_comb)
