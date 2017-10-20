def parseLine(line):
    fields = line.split('|')
    if len(fields) != 7:
        return None
    ent = {
        'registry': fields[0],
        'cc': fields[1],
        'type': fields[2],
        'start': fields[3],
        'value': fields[4],
        'status': fields[5],
        'extensions': fields[6],
    }
    return ent

def parseFile(filename):
    ents = []
    with open(filename, "rb") as fin:
        for line in fin:
            ent = parseLine(line)
            if ent is not None:
                ents.append(ent)
    return ents

def filterFuncIPv4(ent):
    return ent['type'] == 'ipv4'

def filterFuncIPv4CN(ent):
    return ent['type'] == 'ipv4' and ent['cc'] == 'CN'

def ipToNum(ip):
    ds = [int(i) for i in ip.split('.')]
    num = ds[0] << 24
    num += ds[1] << 16
    num += ds[2] << 8
    num += ds[3]
    return num

def num2IP(num):
    num = num & 0xffffffff
    return '%d.%d.%d.%d' % (num >> 24, (num >> 16) & 0xff, (num >> 8) & 0xff, num & 0xff)


def mergeIPv4(ents, filterFunc=None):
    if filterFunc is None:
        filterFunc = filterFuncIPv4
    ipPairs = []
    for ent in ents:
        if not filterFunc(ent):
            continue
        ipNum = ipToNum(ent['start'])
        value = int(ent['value'])
        ipPairs.append((ipNum, ipNum + value))

    ipPairsSorted = sorted(ipPairs, cmp=lambda a, b: a[0] < b[0])
    if len(ipPairsSorted) <= 1:
        return ipPairsSorted
    ipPairsDense0 = []
    lastStart, lastEnd = ipPairsSorted[0]
    for start, end in ipPairsSorted[1:]:
        if lastEnd == start:
            lastEnd = end
        else:
            ipPairsDense0.append((lastStart, lastEnd))
            lastStart = start
            lastEnd = end
    ipPairsDense0.append((lastStart, lastEnd))

    lastStart, lastEnd = ipPairsDense0[0]
    for start, end in ipPairsDense0[1:]:
        print num2IP(lastStart), num2IP(lastEnd), lastEnd - lastStart, start - lastEnd
        lastStart, lastEnd = start, end
    print num2IP(lastStart), num2IP(lastEnd), lastEnd - lastStart
    print len(ipPairs), len(ipPairsSorted), len(ipPairsDense0)
    # As of 2017-10-20
    #
    #   8017 8017 3559

# https://ftp.apnic.net/stats/apnic/delegated-apnic-latest
filename = "delegated-apnic-latest"
ents = parseFile(filename)
mergeIPv4(ents, filterFunc=filterFuncIPv4CN)
