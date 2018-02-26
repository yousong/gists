import datetime
import pytz
import pytz.reference

# datetime, https://docs.python.org/2/library/datetime.html
# pytz, http://pytz.sourceforge.net/
#
# TODO
#
# - monotonic time for time measurement
# - datetime arithmetic

def _(msg):
    print
    print msg

def __(msg):
    print msg

_("-- python datetime module only provides tzinfo abstract class")
__("")
__("   \"Native\" datetime means object without timezone info")
__("")
__("   Apps are expected to use/implement their own timezone related adjustments for")
__("   it's \"more political than rational\"")
tzutc = pytz.utc
tztok = pytz.timezone('Asia/Tokyo')
tzloc = pytz.reference.Local

_("-- now() without tz info are the same as with today()")
print datetime.datetime.today()
print datetime.datetime.now()
print datetime.datetime.now(tz=tzutc)

_("-- posix timestamp: seconds from 1970-01-01T00:00:00Z")
import time
ts = time.time()
print ts

_("-- datetime from/to posix timestamp")
dtloc0 = datetime.datetime.fromtimestamp(ts)
dtloc1 = dtloc0.replace(tzinfo=tzloc)
dtutc1 = datetime.datetime.fromtimestamp(ts, tz=tzutc)
dtutc2 = datetime.datetime.utcfromtimestamp(ts)
ts_ = time.mktime(dtloc0.timetuple()) # tuple must express local time
print dtloc0
print dtloc1
print dtutc1
print dtutc2
print ts_

_("-- convert between non-native datetime")
dt = datetime.datetime.now(tz=tzloc)
dtutc = dt.astimezone(tzutc)
dttok = dt.astimezone(tztok)
print dt
print dtutc
print dttok

_("-- strftime and strptime")
timestr = "2017-06-19T21:56:18Z" # Z means timezone UTC
timefmt = '%Y-%m-%dT%H:%M:%SZ'
dt0 = datetime.datetime.strptime(timestr, timefmt)
dt1 = dt0.replace(tzinfo=tzutc)
dt2 = dt1.astimezone(tzloc)
timefmt_ = '%Y-%m-%d %H:%M:%S'
timestr1 = dt0.strftime(timefmt_)
timestr2 = dt2.strftime(timefmt_)
print dt0
print dt1
print dt2
print timestr1
print timestr2
