#!/usr/bin/env python

import websocket
import ssl
import socket

cookie = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE0ODE4NTk0OTkzMTUsImlzcyI6InJlc3BvbnNlLWY1ZTIyZjdhLTZjYWUtNDdhMS04MzQ3LWYyNGZhMjk1MTI4MSIsImlhdCI6MTQ4MTgyMzQ5OTMxNSwiYXV0aG9yaXRpZXMiOlsiZjVlMjJmN2EtNmNhZS00N2ExLTgzNDctZjI0ZmEyOTUxMjgxIl0sInVzZXJfbmFtZSI6ImxvY2FsIn0.OcTxzwLPpq-_76PpkIGu2lOel6dp--eyp7egzuNQOEWGeu1c4EZxA5the5CWYU6V7pC3QQ9jzez4sW_rCYdZOCXyu16rJe_RTtlkdAhyuUl9cKx1Dtj76GorUhpBZWw33VMPKBVfxiCE6DQjYfaCoimEenVs4L6TmClTvxBgMzYI7ec6FmXw1oLpTUmTMyNyel3-PwDs3rXBcyhpgqMvTs8AII0yWHXgsKtL6VcXmhyIOzJEsG6nbrZCiPm06uSFNbyXLJornMG4-Tz8R3wHGj4rydgSt_S2MswwPstsK89GvQF_E_4kyvYMW18Ss0Le9r4krxIkPavdhSb_pPXrpA'
header = {"Authorization: Bearer {}".format(cookie)}
# host = '10.101.217.122'
host = '10.101.217.183'
# ws_url = 'wss://{}:7003/response/socket'.format(host)
ws_url = 'wss://{}:443/administration/socket'.format(host)
print('==== ws_url: {}'.format(ws_url))
websocket.enableTrace(True)
ws = websocket.create_connection(
        ws_url, sslopt={'cert_reqs': ssl.CERT_NONE},
        http_proxy_host=host, http_proxy_port=443,
        origin="https://{}:7003".format(host),
        header=header)
