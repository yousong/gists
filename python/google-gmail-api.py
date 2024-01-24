from __future__ import print_function
import os

from googleapiclient import discovery
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow


# Interesting links
#
# Google API Discovery Service
#
# - What is the Google API Discovery Service, https://developers.google.com/discovery/
# - Google API Explorer, https://developers.google.com/apis-explorer/
# - A glance at explorer API, https://www.googleapis.com/discovery/v1/apis
#
# GMail API
#
# - Python Quickstart, https://developers.google.com/gmail/api/quickstart/python
# - A glance at GMail API, https://www.googleapis.com/discovery/v1/apis/gmail/v1/rest
#
# Process
#
# 1. Needs to access user data
# 2. Needs OAuth client ID (client_secret.json)
# 3. Needs to create a credential because OAuth client ID is a credential
# 4. Needs to enable GMail API for a project
# 5. Needs to create a project in Google Developers Console
#

# If modifying these scopes, delete your previously saved credentials
# at ~/.credentials/gmail-python-quickstart.json
#
# https://developers.oogle.com/gmail/api/auth/scopes
SCOPES = 'https://www.googleapis.com/auth/gmail.readonly'
SCOPES = ['https://mail.google.com/']
CLIENT_SECRET_FILE = 'client_secret.json'
APPLICATION_NAME = 'Gmail API Python Quickstart'


def get_credentials():
    """Gets valid user credentials from storage.

    If nothing has been stored, or if the stored credentials are invalid,
    the OAuth2 flow is completed to obtain the new credentials.

    Returns:
        Credentials, the obtained credential.
    """
    home_dir = os.path.expanduser('~')
    credential_dir = os.path.join(home_dir, '.credentials')
    if not os.path.exists(credential_dir):
        os.makedirs(credential_dir)
    credential_path = os.path.join(credential_dir,
                                   'gmail-python-quickstart.json')

    creds = None
    # The file token.json stores the user's access and refresh tokens, and is
    # created automatically when the authorization flow completes for the first
    # time.
    if os.path.exists(credential_path):
        creds = Credentials.from_authorized_user_file(credential_path, SCOPES)
    # If there are no (valid) credentials available, let the user log in.
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                CLIENT_SECRET_FILE, SCOPES)
            creds = flow.run_local_server(port=0, open_browser=False)
        # Save the credentials for the next run
        with open(credential_path, 'w') as token:
            token.write(creds.to_json())
    return creds


def threads_trash(service, threads):
    def batchcb(reqid, resp, exc):
        if exc:
            print('failed', req, exc)

    batchreq = service.new_batch_http_request(callback=batchcb)
    count = 0
    for t in threads:
        tid = t['id']
        req = service.users().threads().trash(userId='me', id=tid)
        batchreq.add(req, request_id=tid)

        count += 1
        if count >= 10:
            batchreq.execute()
            batchreq = service.new_batch_http_request(callback=batchcb)
            count = 0
    if count > 0:
        batchreq.execute()

def main(q):
    """Shows basic usage of the Gmail API.

    Creates a Gmail API service object and outputs a list of label names
    of the user's Gmail account.
    """
    credentials = get_credentials()
    service = discovery.build('gmail', 'v1', credentials=credentials)

    fields = 'threads(id)'
    print(q)
    while True:
        results = service.users().threads().list(userId='me', q=q, fields=fields).execute()
        if 'threads' in results:
            threads = results['threads']
            threads_len = len(threads)
            if threads_len:
                print(threads_len)
                threads_trash(service, threads)
            else:
                break
        else:
            break

def cleanupLabels():
    labels = [
        'bird-users',
        'bsd-freebsd-arm',
        'buildroot-crosstool-ng',
        'busybox',
        'debian-arm',
        'dnsmasq-discuss',
        'golang',
        'haproxy',
        'linux-linux-sunxi-cubieboard',
        'linux-lvs',
        'linux-riscv',
        'linux-virtiofs',
        'linux-wireguard',
        'linux-xdp',
        'lua-l',
        'musl-libc',
        'nginx-devel',
        'openvpn-devel',
        'openwrt-devel',
        'openwrt-devel-forum',
        'openwrt-devel-luci',
        'openwrt-devel-mt76',
        'openwrt-devel-openwrt-dev',
        'ovs-ovs-dev',
        'yunionio',
    ]
    for label in labels:
        q = f'label:{label} is:unread'
        main(q)

def cleanupByQueries():
    qs = [
        'list:(centos-devel.centos.org)',
        'list:(<p4-discuss.lists.p4.org>)',
        'list:(<p4-dev.lists.p4.org>)',
        'from:(errata@redhat.com)',
    ]
    for q in qs:
        q = f'{q} is:unread'
        main(q)

if __name__ == '__main__':
    cleanupByQueries()
