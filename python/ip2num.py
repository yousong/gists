def ip2num(ip):
    ds = [int(i) for i in ip.split('.')]
    num = ds[0] << 24
    num += ds[1] << 16
    num += ds[2] << 8
    num += ds[3]
    return num

def ip2num(ip):
    return sum(int(d) << (24 - (i << 3)) for i, d in enumerate(ip.split('.')))

def num2ip(num):
    num = num & 0xffffffff
    return '%d.%d.%d.%d' % (num >> 24, (num >> 16) & 0xff, (num >> 8) & 0xff, num & 0xff)
