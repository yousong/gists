from datetime import datetime, timedelta
from pytz import timezone
import pytz

TIME_ZONE = 'Asia/Shanghai'

_datetime_names = {
    'cloudpub': {
        'fmt': '%Y-%m-%d %H:%M:%S',
        'tz': timezone(TIME_ZONE),
    },
    'cloudpub_date': {
        'fmt': '%Y-%m-%d',
        'tz': timezone(TIME_ZONE),
    },
    'cloudpub_epoch': {
        'fmt': '%s',
        'tz': timezone(TIME_ZONE),
        'fmt_post': lambda s: int(s),
    },
    'cloud': {
        # The final "Z" is Zulu (UTC) time zone designator.
        'fmt': '%Y-%m-%dT%H:%M:%SZ',
        'tz': pytz.utc,
    },
}

def datetime_from_str(str_, name_from):
    from_fmt = _datetime_names[name_from]['fmt']
    from_tz = _datetime_names[name_from]['tz']
    dt = datetime.strptime(str_, from_fmt)
    dt_from = dt.replace(tzinfo=from_tz)
    return dt_from

def datetime_to_tz(dt_from, name_to):
    to_tz = _datetime_names[name_to]['tz']
    dt_to = dt_from.astimezone(to_tz)
    return dt_to

def datetime_to_fmt(dt_from, name_to):
    to_fmt = _datetime_names[name_to]['fmt']
    to_tz = _datetime_names[name_to]['tz']
    fmt_post = _datetime_names[name_to].get('fmt_post')

    dt_to = dt_from.astimezone(to_tz)
    ret_to = dt_to.strftime(to_fmt)
    if fmt_post:
        ret_to = fmt_post(ret_to)
    return ret_to

def datetime_tz_convert(str_from, name_from, name_to):
    """
        ValueError can be raised from strptime().
    """
    dt_from = datetime_from_str(str_from, name_from)
    ret_to = datetime_to_fmt(dt_from, name_to)

    return ret_to

def date_range_last(n_days=1):
    fmt = _datetime_names['cloud']['fmt']
    tz = _datetime_names['cloudpub']['tz']
    cloud_tz = _datetime_names['cloud']['tz']

    # local date with time being 00:00:00
    now = datetime.now(tz).date()
    now = datetime(now.year, now.month, now.day)
    prev = now - timedelta(days=n_days)

    # cloud datetime.
    now = tz.localize(now).astimezone(cloud_tz)
    prev = tz.localize(prev).astimezone(cloud_tz)

    since = prev.strftime(fmt)
    until = now.strftime(fmt)

    return (since, until)
