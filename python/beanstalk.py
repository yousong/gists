import unittest
import beanstalkc

# https://github.com/earl/beanstalkc/blob/master/TUTORIAL.mkd
class T(unittest.TestCase):
    def test_basic(self):
        b = beanstalkc.Connection(host='localhost', port=11300)
        b.put('1')
        job = b.reserve()
        print job.body
        job.delete()
        b.close()

    def test_order(self):
        b = beanstalkc.Connection(host='localhost', port=11300)
        b.put('1')
        b.put('2')
        b.put('3')
        job = b.reserve()
        job.release()
        # 1, 2, 3 in the order of put
        jobs = self._reserve_all(b)
        for job in jobs:
            print job.body
            job.delete()
        b.close()

    def _reserve_all(self, b):
        jobs = []
        while True:
            job = b.reserve(timeout=0)
            if job:
                jobs.append(job)
            else:
                break
        return jobs

if __name__ == '__main__':
    unittest.main()
