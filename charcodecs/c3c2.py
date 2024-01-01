import codecs
import sys

def b(bs):
    bs1=b''
    sz=len(bs)
    i=0
    while i < sz:
        c = bs[i]
        if c == 0xc3:
            i+=1
            bs1 = bs1 + (bs[i]|0x40).to_bytes(length=1, byteorder='big')
        elif c == 0xc2:
            i+=1
            bs1 = bs1 + bs[i].to_bytes(length=1, byteorder='big')
        else:
            bs1 = bs1 + c.to_bytes(length=1, byteorder='big')
        i+=1
    return bs1

bs = sys.stdin.buffer.read()
bs1 = b(bs)
s = codecs.decode(bs1, 'gb18030', errors='ignore')
print(s)
