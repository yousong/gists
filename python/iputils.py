def ip2num(ip):
    return sum(int(d) << (24 - (i << 3)) for i, d in enumerate(ip.split('.')))

def num2ip(num):
    num = num & 0xffffffff
    return '%d.%d.%d.%d' % (num >> 24, (num >> 16) & 0xff, (num >> 8) & 0xff, num & 0xff)

def range2preflen(n0, n1):
    if n0 > n1:
        return []
    elif n0 == n1:
        return [ (n0, 32) ]
    else:
        p = 0
        while True:
            down, up = range2pref_downup(n0, p)
            if down < n0 or up >= n1 + 1:
                p1 = p - (up != n1 + 1)
                down1, up1 = range2pref_downup(n0, p1)
                r = [ (n0, 32-p1) ]
                r += range2preflen(up1, n1)
                return r
            else:
                p += 1
                if p > 32:
                    return []

def range2pref_downup(n, p):
    pp = 1 << p
    pp1 = pp - 1
    up = (n + pp1) & (0xffffffff & ~pp1)
    if up == n:
        down = up
        up += pp
    else:
        down = up - pp
    return down, up
