from __future__ import print_function
import httplib2
import os

from apiclient import discovery
from oauth2client import client
from oauth2client import tools
from oauth2client.file import Storage

try:
    import argparse
    flags = argparse.ArgumentParser(parents=[tools.argparser]).parse_args()
except ImportError:
    flags = None


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
SCOPES = 'https://www.googleapis.com/auth/gmail.readonly'
SCOPES = 'https://mail.google.com/'
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

    store = Storage(credential_path)
    credentials = store.get()
    if not credentials or credentials.invalid:
        flow = client.flow_from_clientsecrets(CLIENT_SECRET_FILE, SCOPES)
        flow.user_agent = APPLICATION_NAME
        if flags:
            credentials = tools.run_flow(flow, store, flags)
        else: # Needed only for compatibility with Python 2.6
            credentials = tools.run(flow, store)
        print('Storing credentials to ' + credential_path)
    return credentials

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
    http = credentials.authorize(httplib2.Http())
    service = discovery.build('gmail', 'v1', http=http)

    fields = 'threads(id)'
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

if __name__ == '__main__':
    qs = [
        'label:AD is:unread',
        'label:ovs-ovs-dev is:unread',
        'label:ovs-ovs-discuss is:unread',
        'label:golang is:unread',
        'label:lua-l is:unread',
        'label:musl-libc is:unread',
        'label:openwrt-devel-packages is:unread',
        'label:openwrt-devel-luci is:unread',
        'label:core-mentorship is:unread',
        'label:buildroot-crostool-ng is:unread',
        'label:nginx-devel is:unread',
    ]
    for q in qs:
        print(q)
        main(q)
