from __future__ import print_function
import sys
import threading
import traceback
import time

def print_stacks():
    frames = sys._current_frames()
    for t in threading.enumerate():
        tident = t.ident
        tframe = frames.get(tident)
        if tframe:
            stack = traceback.extract_stack(tframe)
            print(stack)

class T(threading.Thread):
    def __init__(self, sem):
        super(T, self).__init__()
        self.sem = sem

    def run(self):
        sem.acquire()

count = 3
sem = threading.Semaphore(0)
for i in range(count):
    T(sem).start()
print_stacks()
for i in range(count):
    sem.release()
