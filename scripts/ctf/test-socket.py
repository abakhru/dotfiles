import asyncio
import json
import re
import requests
import ssl
import sys
from time import sleep
import websocket

HOST = "10.101.217.183"
# PORT = 8080
PORT = 7003

NULL = b'\x00'


def stomp(command, header, body=None):
    """ Creates a STOMP frame from a command string, header dictionary and body dictionary """

    msg = command.encode() + b'\n'
    for key, value in header.items():
        msg += key.encode() + b':' + value.encode() + b'\n'
    if body is not None:
        msg += b'content-type:application/json\n'
        msg += b'\n' + json.dumps(body).encode()
    else:
        msg += b'\n'
    msg += NULL
    return msg


line_end = b'\n|\r\n'
le = b'(' + line_end + b')'
preamble_end = b''.join([le, le])
# LINE_END_RE = re.compile(b'\n|\r\n')
LINE_END_RE = re.compile(line_end)
# PREAMBLE_END_RE = re.compile(b'\n\n|\r\n\r\n')
PREAMBLE_END_RE = re.compile(preamble_end)
HEADER_LINE_RE = re.compile(b'(?P<key>[^:]+)[:](?P<value>.*)')
_HEADER_ESCAPES = {
    '\r': '\\r',
    '\n': '\\n',
    ':': '\\c',
    '\\': '\\\\',
}
_HEADER_UNESCAPES = dict((value, key) for (key, value) in _HEADER_ESCAPES.items())


def _unescape_header(matchobj):
    escaped = matchobj.group(0)
    unescaped = _HEADER_UNESCAPES.get(escaped)
    if not unescaped:
        # TODO: unknown escapes MUST be treated as fatal protocol error per spec
        unescaped = escaped
    return unescaped


def parse_headers(lines, offset=0):
    """
    Parse the headers in a STOMP response
    :param list(str) lines: the lines received in the message response
    :param int offset: the starting line number
    :rtype: dict(str,str)
    """

    headers = {}
    for header_line in lines[offset:]:
        if header_line:
            header_match = HEADER_LINE_RE.match(header_line)
        if header_match:
            key = header_match.group('key').decode()
            key = re.sub(r'\\.', _unescape_header, key)
            if key not in headers:
                value = header_match.group('value').decode()
                value = re.sub(r'\\.', _unescape_header, value)
                headers[key] = value
    return headers


def frame(stomp_msg):
    """frame creates stomp frame from the stomp message.

    Args:
        stomp_msg: (str or bytes) the well formed stomp message

    Returns:
        stomp frame (dict of (str, dict of headers (str, str), str)
    """

    if type(stomp_msg) is str:
        f = stomp_msg.encode()
    else:
        f = stomp_msg
    cmd = ''
    headers = {}
    body = None
    if f == b'\x0a':
        return {'heartbeat', headers, body}

    mat = PREAMBLE_END_RE.search(f)
    if mat:
        preamble_end = mat.start()
        body_start = mat.end()
    else:
        preamble_end = len(frame)
        body_start = preamble_end

    if preamble_end > 0:
        preamble = f[0:preamble_end]
    else:
        print('No preamble found')
        preamble = b''

    preamble_lines = LINE_END_RE.split(preamble)
    body = f[body_start:]

    first_line = 0
    while first_line < len(preamble_lines) and len(preamble_lines[first_line]) == 0:
        first_line += 1

    cmd = preamble_lines[first_line].decode()
    headers = parse_headers(preamble_lines, first_line + 1)

    return {"cmd": cmd, "headers": headers, "body": body}


def frame__str__(f):
    """frame__str__ is a basic serialization attempt for frames

    Some of the things that aren't handled by json.dumps are:
        1) byte string characters instead of strings
        2) NULL characters (sometimes that's the body)

    We will attempt to turn strings that contain null characters into the string NULL.
    We will attempt to avoid all type failures by converting bytes into strings before using json
    to dump the string version of the dictionary out.

    Args:
        f: (dict of cmd: (str), headers, (dict of str:str), body (byte_string))

    Returns:
        string representation ready for printing
    """

    print('Type of cmd is: {}'.format(type(f['cmd'])))
    if type(f['cmd']) is bytes:
        f['cmd'] = f['cmd'].decode()

    f['body'] = f['body'].decode()
    if type(f['body']) is bytes:  # Remove trailing null
        f['body'] == f['body'][:f['body'].find(b'\x00')].decode()

    try:
        f['body'] = json.loads(f['body'][:f['body'].find(b'\x00'.decode())])
    except:
        pass

    return json.dumps(f, indent=4)


# print('Disable the warnings about not verifying certificates')
# Disable the warnings about not verifying certificates
requests.packages.urllib3.disable_warnings()

APP_PREFIX = "/ws/response"
# print('Login to the service')
# Login to the service
login_url = 'https://{0}:{1}/rsa/'.format(HOST, PORT)
post_data = {"password": "changeMe", "type": ".IdPasswordCredential", "id": "local"}
HEADERS = {'content-type': 'application/json'}
s = requests.Session()
s.trust_env = False
r = s.post(login_url, data={'username': 'admin', 'password': 'netwitness'}, verify=False)

# print('Extract the session id and CSRF token from the response')
# Extract the session id and CSRF token from the response
token = r.headers['x-csrf-token']
cookie = "JSESSIONID=" + r.cookies['JSESSIONID']

# print('Connect to the SockJS websocket endpoint, also disabling any certificate validation')
# Connect to the SockJS websocket endpoint, also disabling any certificate validation
# ws_url = 'wss://{0}:{1}/demo/socket/websocket'.format(HOST, PORT)

print('Enabling websocket trace')
websocket.enableTrace(True)

# Connecting to wss://{0}:{1}/response/socket/websocket'.format(HOST, PORT))
print('# Connecting to wss://{0}:{1}/response/socket/websocket'.format(HOST, PORT))
ws_url = 'wss://{0}:{1}/response/socket/websocket'.format(HOST, PORT)
ws = websocket.create_connection(ws_url, sslopt={"cert_reqs": ssl.CERT_NONE}, cookie=cookie)

# Send the CONNECT frame with the CSRF token from above
print('# Send the CONNECT frame with the CSRF token from above')
ws.send(stomp('CONNECT', {'accept-version': '1.0,1.1,2.0', 'host': HOST, 'X-CSRF-TOKEN': token}))

t = ws.recv()
fd = frame(t)
print('After CONNECT the frame is: {}'.format(frame__str__(fd)))

# Subscribe to /topic/incidents/new'
print('# Subscribe to /topic/incidents/new - should get existing data')
ws.send(stomp('SUBSCRIBE', {'id': 'req-1', 'destination': '/topic/incidents/new'}))
# Nothing received after this
# t = ws.recv()
# fd = frame(t)
# print('After /topic/incidents/new SUBSCRIBE the frame is: {}'.format(frame__str__(fd)))

# Subscribe to topic/incidents/update
print('# Subscribe to /topic/incidents/update')
ws.send(stomp('SUBSCRIBE', {'id': 'update1', 'destination': '/topic/incidents/update'}))
# Nothing received after this
# t = ws.recv()
# fd = frame(t)
# print('After /topic/incidents/update SUBSCRIBE the frame is: {}'.format(frame__str__(fd)))

# Subscribe to /user/queue/categories
print('# Subscribe to /user/queue/categories')
ws.send(stomp('SUBSCRIBE', {'id': 'categories', 'destination': '/user/queue/categories'}))
# Nothing received after this
# t = ws.recv()
# fd = frame(t)
# print('After /topic/incidents/update SUBSCRIBE the frame is: {}'.format(frame__str__(fd)))

message = {}
ws.send(stomp('SEND', {'destination': '{}/categories'.format(APP_PREFIX)}, message))
t = ws.recv()
fd = frame(t)
print('After sending for categories: {}'.format(frame__str__(fd)))

message = {'id': 'req-01'
    , 'page': None
    , 'stream': {'limit': 5}
    , 'sort': [{'field': 'prioritySort', 'descending': True}]
    , 'filter': [
        {'field': 'statusSort'
            , 'value': 0
            , 'values': None
            , 'range': None
            , 'isNull': False
         }
    ]
           }

stomp_frame = stomp('SEND', {'destination': '{}/incidents'.format(APP_PREFIX)}, message)

print('Sending frame: {}'.format(frame__str__(frame(stomp_frame))))
ws.send(stomp_frame)

t = ws.recv()
fd = frame(t)
print('After sending req-01 frame is: {}'.format(frame__str__(fd)))

print('# Create a second request')
# Create a second request
message = {"id": "req-02"
    , "page": None
    , "stream": {
        "limit": 1
    }
    , "sort": [{
        "field": "prioritySort"
        , "descending": True
    }]
    , "filter": [{
        "field": "statusSort",
        "value": 0,
        "values": None,
        "range": None,
        "isNull": False
    }]
           }

ws.send(stomp('SEND', {'destination': '{}/incidents'.format(APP_PREFIX)}, message))

frames = 0
sleeps = 0
print('Sent request 2, now trying to undestand receiving')
while (frames < 3) and (sleeps < 10):
    print('Entering loop; frames = {} and sleep = {}'.format(frames, sleeps))
    fd = frame(ws.recv())
    print('received frame is: {}'.format(frame__str__(fd)))
    sleep(2)
    frames += 1
    sleeps += 1

if frames == 3:
    print('Got all 3 chunks')

print('Disabling websocket trace')
websocket.enableTrace(False)

print('Gracefully close the connection')
# Gracefully close the connection
ws.close()
sys.exit()

# Send a message
ws.send(stomp('SEND', {'destination': '/ws/person/greet'},
              {'name': 'Abram', 'email': 'abram.thielke@rsa.com'}))

# Subscribe to the user queue
ws.send(stomp('SUBSCRIBE', {'id': '1', 'destination': '/user/queue/person/get'}))
ws.send(stomp('SEND', {'destination': '/ws/person/get'}, 'some-uuid-here'))

# This is the Person response from the server
t = ws.recv()
print(t)

# Cleanup that subscription
ws.send(stomp('UNSUBSCRIBE', {'id': '1'}))

# Subscribe to a broadcast topic
ws.send(stomp('SUBSCRIBE', {'id': '2', 'destination': '/topic/uuid'}))

# Read 3 responses (from the topic we just subscribed to)
for x in range(0, 3):
    t = ws.recv()
    print(t)

# Gracefully close the connection
ws.close()
