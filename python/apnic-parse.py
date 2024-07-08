import iputils
import sys

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
    with open(filename, "r") as fin:
        for line in fin:
            ent = parseLine(line)
            if ent is not None:
                ents.append(ent)
    return ents

def filterFuncIPv4(ent):
    return ent['type'] == 'ipv4'

def filterFuncIPv4CN(ent):
    return ent['type'] == 'ipv4' and ent['cc'] == 'CN'

def IpPairs(ents, filterFunc=None, sort=False):
    if filterFunc is None:
        filterFunc = filterFuncIPv4
    pairs = []
    for ent in ents:
        if not filterFunc(ent):
            continue
        ipNum = iputils.ip2num(ent['start'])
        value = int(ent['value'])
        pairs.append((ipNum, ipNum + value))

    if sort:
        pairs = sorted(pairs, key=lambda a: a[0])
    return pairs

def IpPairsMerge(pairs):
    if len(pairs) <= 1:
        return pairs
    pairsDensed = []
    lastStart, lastEnd = pairs[0]
    for start, end in pairs[1:]:
        if lastEnd == start:
            lastEnd = end
        else:
            pairsDensed.append((lastStart, lastEnd))
            lastStart = start
            lastEnd = end
    pairsDensed.append((lastStart, lastEnd))
    return pairsDensed

def IpPairsToNetPreflen(pairs):
    netprefs = []
    for start, end in pairs:
        for n, preflen in iputils.range2preflen(start, end - 1):
            net = iputils.num2ip(n)
            netprefs.append((net, preflen))
    return netprefs

# wget -c https://ftp.apnic.net/stats/apnic/delegated-apnic-latest
# rg -F '|CN|ipv6|' delegated-apnic-latest | cut -d'|' -f4,5 | tr '|' '/'
filename = "delegated-apnic-latest"
ents = parseFile(filename)
pairs = IpPairs(ents, filterFunc=filterFuncIPv4CN, sort=True)
pairs = IpPairsMerge(pairs)
netprefs = IpPairsToNetPreflen(pairs)
for net, preflen in netprefs:
    sys.stdout.write("%s/%d\n" % (net, preflen))
