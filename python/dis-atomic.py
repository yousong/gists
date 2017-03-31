#
# Inspect Python virtual machine instructions with dis
#
# Adapted from http://stackoverflow.com/questions/1312331/using-a-global-dictionary-with-threads-in-python/32303835#32303835
#

import dis
demo = {}

#  8           0 LOAD_CONST               1 ('Jatin Kumar')
#              3 LOAD_GLOBAL              0 (demo)
#              6 LOAD_CONST               2 ('name')
#              9 STORE_SUBSCR
#             10 LOAD_CONST               0 (None)
#             13 RETURN_VALUE
def set_dict():
    demo['name'] = 'Jatin Kumar'


# 11           0 LOAD_GLOBAL              0 (demo)
#              3 LOAD_CONST               1 ('name')
#              6 DELETE_SUBSCR
#
# 12           7 LOAD_GLOBAL              0 (demo)
#             10 LOAD_ATTR                1 (pop)
#             13 LOAD_CONST               1 ('name')
#             16 LOAD_CONST               0 (None)
#             19 CALL_FUNCTION            2
#             22 POP_TOP
#             23 LOAD_CONST               0 (None)
#             26 RETURN_VALUE
def del_dict():
    del demo['name']
    demo.pop('name', None)

dis.dis(set_dict)
dis.dis(del_dict)
