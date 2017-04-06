from collections import deque
from timeit import timeit

def deque_action(n):
    d = deque()
    for i in range(n):
        d.append(i)
    while len(d):
        j = d.popleft()

def list_action(n):
    d = []
    for i in range(n):
        d.append(i)
    while len(d):
        j = d.pop(0)

def test(who):
    what = '%s_action(100000)' % who
    setup = 'from __main__ import %s_action' % who
    time = timeit(what, number=1, setup=setup)
    print who, time

test('deque')
test('list')
