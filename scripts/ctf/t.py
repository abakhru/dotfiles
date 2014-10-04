#!/usr/bin/env python

from datetime import datetime
import asyncore
from smtpd import SMTPServer

from ctf.framework.logger import LOGGER
LOGGER.setLevel('DEBUG')

class EmlServer(SMTPServer):
    no = 0
    def process_message(self, peer, mailfrom, rcpttos, data):
        filename = '%s-%d.eml' % (datetime.now().strftime('%Y%m%d%H%M%S')
                                  , self.no)
        f = open(filename, 'w')
        f.write(data)
        f.close
        print '%s saved.' % filename
        self.no += 1


def run():
    foo = EmlServer(('localhost', 22225), None)
    """
    try:
        asyncore.loop()
    except KeyboardInterrupt:
        pass
    """
    loop_counter = 0
    while asyncore.socket_map:
        loop_counter += 1
        LOGGER.debug('loop_counter=%s', loop_counter)
        asyncore.loop(timeout=1, count=1)
        if loop_counter == 2:
            break

def check():
    options_list = ['-Dconnectorport=4445'
                    , '-Dcarloslistenport=4444'
                    , '-Drmiport=4446'
                    , '-u', 'jms://localhost:12245'
                    , '-h', 'aaaa']
    args_list = ['-Dcom.rsa.netwitness.carlos.LOG_ENABLE_SYSOUT=true'
                 , '-classpath', 'CLASSPATH'
                 , 'ESACommandLine']

    # if ports are defined as -D options, make it prefix to classpth
    if '-D' in options_list[0]:
        temp_list1 = []
        temp_list2 = []
        for i in options_list:
            if i.startswith('-D'):
                temp_list1.append(i)
            else:
                temp_list2.append(i)
        args = ' '.join(temp_list1 + args_list + temp_list2)
        print args
    return


if __name__ == '__main__':
        #run()
        check()
