"""test-socket.py: test script for validating microservice calls."""

import inflection
import io
import os
import json
import random
import requests
import ssl
import websocket
import yaml
import sys

ACCESS_TOKEN = 'access_token'
AUTH_COOKIE = ACCESS_TOKEN + '={}'

CONSOLE_WRAP_LEN = 80
CONSOLE_MSG_SEP = '-' * CONSOLE_WRAP_LEN

SOCKET_TIMEOUT = 60
SOCKET_TIMEOUT_FOR_STOMP_DISCONNECT = 5

REQ_KEY_FILTER = "filter"
REQ_KEY_STREAM = "stream"
REQ_KEY_PAGE = "page"
REQ_KEY_SORT = "sort"

RESP_KEY = "response"

HEADER_CT = "content-type"
CT_JSON = "application/json"

SUB_ID_START = random.randint(1, 5000)
__sub_id = -1


def get_new_sub_id():
    """Get a new subscription id."""
    global __sub_id
    if __sub_id == -1:
        __sub_id = SUB_ID_START
    else:
        __sub_id += 1
    return __sub_id


class SomeKindOfError(Exception):
    """Something went wrong with something, somewhere in this script."""

    def __init__(self, msg, data=None):
        """Class ctor."""
        self.msg = msg
        self.data = data

    def __str__(self):
        """Return a string representation of exception."""
        if self.data is not None:
            return "{}\nresponse dump => \n".format(self.msg, self.data)
        return self.msg


class STOMPResponse:
    """A STOMP response message."""

    def __init__(self, msg_type, headers, body):
        """Class ctor."""
        self.msg_type = msg_type
        self.headers = headers
        self.body = body
        self.is_valid = False \
            if msg_type is None and headers is None and body is None \
            else True

    def __str__(self):
        """String representation of STOMP response."""
        s = "{}\n".format(self.msg_type)
        for key in sorted(self.headers):
            s += "{}: {}\n".format(key, self.headers[key])
        s += "\n"

        if self.body is not None:
            if (HEADER_CT in self.headers) \
                    and (CT_JSON in self.headers[HEADER_CT]):
                s += json.dumps(json.loads(self.body),
                                indent=2, sort_keys=True, ensure_ascii=False)
            else:
                s += str(self.body)

        return s + '^@'

    def valid(self):
        """Show if a response is valid."""
        return self.is_valid

    @staticmethod
    def from_str(response_str):
        """Create a STOMP respnse object from a string."""
        if len(response_str) == 0:
            raise SomeKindOfError("Empty STOMP response!")
        buffer = io.StringIO(initial_value=response_str)
        msg_type = ''
        headers = {}
        l = buffer.readline()
        while (True):
            l = l.strip()
            if len(l) == 0:
                if len(msg_type) == 0:
                    msg = "invalid STOMP response: found newline before " + \
                          "message type!"
                    raise SomeKindOfError(msg, response_str)
                break
            if len(msg_type) == 0:
                msg_type = l
            else:
                if ':' not in l:
                    msg = "invalid STOMP response: error in header ({})"
                    raise SomeKindOfError(msg.format(l))
                kv = l.split(':')
                headers[kv[0]] = kv[1]
            l = buffer.readline()
        body = io.StringIO()
        c = buffer.read(1)
        while (True):
            # print('{} => {}'.format(c, ord(c)))
            if ord(c) == 0:
                break
            else:
                body.write(c)
            c = buffer.read(1)
        return STOMPResponse(msg_type, headers, body.getvalue())


def get_oauth_url(host, port, uri, secure):
    """Get login url."""
    return 'http{0}://{1}:{2}{3}'.format(
        's' if secure else '', host, port, uri)


def get_socket_url(host, port, uri, secure):
    """Get the socket url."""
    return "ws{0}://{1}:{2}{3}/websocket".format(
        's' if secure else '', host, port, uri)


def write_stomp_response(stomp_response, response_count=0, destination=None):
    """Print STOMP response, taking streaming into account."""
    if stomp_response is not None:
        dest_str = ""
        if destination is not None:
            dest_str = " for {}".format(destination)
        if response_count > 0:
            print('\n  *** stream response #{}{} ***\n'.format(
                response_count, dest_str))
        print(stomp_response)
        print(CONSOLE_MSG_SEP)


def make_stomp_message(command, headers, body=None):
    """Build a STOMP message."""
    msg = command + "\n"
    for key, value in headers.items():
        msg += key + ":" + value + "\n"
    if body is not None:
        msg += "content-type:application/json\n"
        msg += "\n" + json.dumps(body, ensure_ascii=False)
    else:
        # according to the spec there is no new line between headers
        # and null byte for the DISCONNECT command
        # see https://stomp.github.io/stomp-specification-1.2.html#DISCONNECT
        if command is not 'DISCONNECT':
            msg += "\n"
    msg += '\x00'
    return msg


def build_nwm_request(filters=None, stream=None, page=None, sort=None):
    """Build a NetWitness microservice request JSON object."""
    request = {}
    if filters is not None:
        request[REQ_KEY_FILTER] = filters
    if stream is not None:
        request[REQ_KEY_STREAM] = stream
    if page is not None:
        request[REQ_KEY_PAGE] = page
    if sort is not None:
        request[REQ_KEY_SORT] = sort
    return request


def build_headers(**kwargs):
    """Build a dictionary containing STOMP headers."""
    headers = {}
    for key, val in kwargs.items():
        if '-' not in key and '_' not in key:
            k = inflection.underscore(key)
            k = inflection.dasherize(k)
            headers[k] = val
        else:
            headers[key] = val
    # Do I need to do this?  Can I just pass back kwargs?
    return headers


def build_params(**kwargs):
    """Build a dictionary from key/value pairs."""
    return build_headers(**kwargs)


def stomp_subscribe(ws, dest):
    """Do a STOMP subscribe."""
    sub_id = get_new_sub_id()
    sub_headers = build_headers(id=str(sub_id), destination=dest)
    stomp(ws, 'SUBSCRIBE', sub_headers)
    return sub_id


def stomp_unsubscribe(ws, sub_id):
    """Do a STOMP unsubscribe."""
    unsub_headers = build_headers(id=str(sub_id))
    stomp(ws, 'UNSUBSCRIBE', unsub_headers)


def service_login(authentication, host):
    """Login to service."""
    login_url = get_oauth_url(host, authentication['port'], authentication['uri'],
                              authentication['secure'])
    post_data = build_params(username=authentication['username']
                             , password=authentication['password']
                             , grant_type='password', client_id='nw_ui')
    print(login_url)
    # post_data = {"password": "changeMe", "type": ".IdPasswordCredential", "id": "local"}
    # HEADERS = {'content-type': 'application/json'}
    print(post_data)
    s = requests.Session()
    s.trust_env = False
    response = s.post(login_url, data=json.dumps(post_data), auth=('nw_ui', ''), verify=False)
                    #   headers=HEADERS)
    json_data = response.json()
    print(json_data)
    ACCESS_TOKEN = 'accessToken'
    if ACCESS_TOKEN not in json_data:
        raise SomeKindOfError('{} not found!'.format(ACCESS_TOKEN))
    return AUTH_COOKIE.format(json_data[ACCESS_TOKEN])


def get_socket(socket, auth_token, host):
    """Get websocket connection to service."""
    ws_url = get_socket_url(host, socket['port'], socket['uri'], socket['secure'])
    websocket.enableTrace(True)
    print('==== ws_url: {}'.format(ws_url))
    ws = websocket.create_connection(
        ws_url, sslopt={'cert_reqs': ssl.CERT_NONE},
        sockopt=[],
        cookie=auth_token)
    ws.timeout = SOCKET_TIMEOUT
    return ws


def destroy_socket(ws):
    """Gracefully close the connection."""
    ws.close()


def get_header_val(headers, header_name):
    """Get a header value."""
    if header_name in headers.keys():
        return headers[header_name]
    return '<ERROR>'


def default_stream_finished(stomp_response, c, subscription):
    """Check response content to see if it's complete.

    Use pyjq to lookup value for meta > complete
    """
    response_rule = subscription[RESP_KEY]
    if 'total' in response_rule:
        return c == response_rule['total']
    f = open('response.txt', 'w')
    f.write(stomp_response.body)
    f.close()

    # return pyjq.first('.meta.complete', json.loads(stomp_response.body),
    #                   default=False)


def connect_socket(ws, host):
    stomp(ws, 'CONNECT', build_headers(acceptVersion='1.0,1.1,1.2', host=host))
    print(ws.recv() + '\n')


def disconnect_socket(ws):
    stomp(ws, 'DISCONNECT', build_headers(receipt='1255'))


def stomp(ws, command, headers, data=None, get_response=False):
    """Send a STOMP message to service."""
    msg = make_stomp_message(command, headers, data)
    print(msg.replace('\x00', '^@') + '\n' + '=' * CONSOLE_WRAP_LEN)
    ws.send(msg)


def process_response(ws, subscription, stream_finished=default_stream_finished):
    t = ws.timeout
    try:

        if RESP_KEY not in subscription:
            r = STOMPResponse.from_str(ws.recv())
            write_stomp_response(r)
            return json.loads(r.body)
        else:
            c = 0
            is_done = False
            while not is_done:
                # time.sleep(2)
                res_txt = ws.recv()
                if len(res_txt) > 0:
                    r = STOMPResponse.from_str(res_txt)
                    c += 1
                    # print(res_txt)
                    write_stomp_response(r, c)
                    is_done = stream_finished(r, c, subscription)

    except websocket.WebSocketTimeoutException:
        print(' timed out\n' + '-' * CONSOLE_WRAP_LEN)
    except Exception as err:
        print(err)
    finally:
        ws.timeout = t

    return None


def test_api(ws, api, func):
    sub_ids = []

    for subscription in api['subscriptions']:
        sub_ids.append(stomp_subscribe(ws, subscription['uri']))

    send = api['send']
    send_uri = send['uri']
    send_cmd_headers = build_headers(destination=send_uri)

    filters = None
    if REQ_KEY_FILTER in send.keys():
        filters = send[REQ_KEY_FILTER]

    stream = None
    if REQ_KEY_STREAM in send.keys():
        stream = send[REQ_KEY_STREAM]

    page = None
    if REQ_KEY_PAGE in send.keys():
        page = send[REQ_KEY_PAGE]

    sort = None
    if REQ_KEY_SORT in send.keys():
        page = send[REQ_KEY_SORT]

    params = build_nwm_request(filters, stream, page, sort)

    if "payload" in send.keys():
        params = send["payload"];

    response_streamed = False
    if send_uri.endswith('/stream'):
        response_streamed = True
    stomp(ws, 'SEND', send_cmd_headers, data=params)

    for subscription in api['subscriptions']:
        r = process_response(ws, subscription)
        ref = api['reference']
        if func:
            func(r, ref)

    for sub_id in sub_ids:
        stomp_unsubscribe(ws, sub_id)

# Disable the warnings about not verifying certificates
requests.packages.urllib3.disable_warnings()


def run_websocket(input_file_name_, output_path_, host, func=None):
    stream = open(input_file_name_, "r", encoding='utf-8')
    test = yaml.load(stream)

    authentication = test['authentication']
    auth_token = service_login(authentication, host)

    for service in test['tests']:
        output_file = open(output_path_ + os.sep + service['output-filename']
                           , 'w', encoding='utf-8')
        orig_stdout = sys.stdout
        sys.stdout = output_file
        socket = service['socket']
        ws = get_socket(socket, auth_token, host)
        connect_socket(ws, host=host)

        for api in service['apis']:
            test_api(ws, api, func)

        disconnect_socket(ws)
        destroy_socket(ws)
        sys.stdout = orig_stdout
        output_file.close()


def main(input_file_name_, output_path_, host_):
    run_websocket(input_file_name_, output_path_, host_)

if __name__ == "__main__":
    if len(sys.argv) > 4:
        print("test_socket.py <input file> <output path>")
        sys.exit(-1)

    input_file_name = sys.argv[1]
    output_path = sys.argv[2]
    host = sys.argv[3]

    main(input_file_name, output_path, host)
