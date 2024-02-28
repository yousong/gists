# c3c2.py

This little script tries to restore character strings from byte sequence.  The input byte sequenced is expected to be product of applying utf8 encoding on each byte of an already gb18030 encoded byte sequence.

E.g. "驴", "\xc2\xbf" gb18030 encoded, "\xc3\x82\xc2\xbf" when again utf8 encoded

UPDATE 2024/02/27: It seems we can achieve the same effect with iconv command

    iconv -f utf8 -t latin1 | iconv -f gb18030 -t utf8
