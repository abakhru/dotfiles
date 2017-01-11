#! /usr/bin/env python

""" publish events to rabbitmq

    Events are published in batches
    Events can be "normal" or "trigger".
       The values of their "user_dst" field are "normal" and "Slaarty Baardfast", respectively.
    For all events, the "event_source_id" field takes values "0", "1", "2", ...
"""
import json
import optparse
import os
import pika
import ssl
import sys
import logging
import time

logging.basicConfig()

# EVENT_TEMPLATE  = """{"event_source_id":"%d", "ec_activity": "Logon", "user_dst": "%s",  "ec_outcome": "Failure", "esa_time": %d }"""
EVENT_TEMPLATE  = """{"ip_src": "%s", "ip_dst": "%s", "id":"%d", "ec_activity": "Logon", "user_dst": "%s",  "ec_outcome": "Failure", "esa_time": %d }"""
NORMAL_USER     = "normal"
TRIGGER_USER    = "Slaarty Baardfast"
HEADERS         = {'esa.event.type':'Event'}
GLOBAL_EXCHANGE = {'virtualhost': '/', 'durable': True, 'type': 'direct'}
LOCAL_EXCHANGE  = {'virtualhost': '/rsa/sa', 'durable': True, 'type': 'headers'}

logging.getLogger('pika').setLevel(logging.DEBUG)

def loadArgs():
    """ get command line arguments """

    defaults = {'number': 100
                , 'batchsize': 5
                , 'sleeptime': 0
                , 'triggerpercent': 100
                , 'exchange': 'esa.events'
                , 'globalengine': False
                , 'printonly': False
                , 'remotehost': '127.0.0.1'}

    usage = '%prog [options] \n\n' + __doc__
    parser = optparse.OptionParser(usage=usage)

    parser.add_option('-n', '--number',
                      type='int', action='store', dest='number',
                      default=defaults['number'],
                      help='number of events to publish in total')
    parser.add_option('-b', '--batchsize',
                      type='int', action='store', dest='batchsize',
                      default=defaults['batchsize'],
                      help='number of events to publish in one go')
    parser.add_option('-s', '--sleep',
                      type='float', action='store', dest='sleeptime',
                      default=defaults['sleeptime'],
                      help='number of seconds to sleep between publishing batches')
    parser.add_option('-t', '--triggerpercent',
                      type='int', action='store', dest='triggerpercent',
                      default=defaults['triggerpercent'],
                      help='percentage of events that are "triggers"')
    parser.add_option('-e', '--exchange',
                      type='string', action='store', dest='exchange',
                      default=defaults['exchange'],
                      help='exchange to publish to')
    parser.add_option('-g', '--globalengine',
                      action='store_true', dest='globalengine',
                      default=defaults['globalengine'],
                      help='publish to an exchange for a global (not default) engine')
    parser.add_option('-r', '--remote',
                      type='string', action='store', dest='remotehost',
                      default=defaults['remotehost'],
                      help='host for esper engine')
    parser.add_option('-p', '--printonly',
                      action='store_true', dest='printonly',
                      default=defaults['printonly'],
                      help='only print the messages; do not publish them')

    return parser.parse_args()


def events(firstId, eventCount, triggerCount, triggerrate):

    val = {"tc": triggerCount}
    i = 1
    def event(eventId):
        user = NORMAL_USER
        if val["tc"] <= i * triggerrate:
            val["tc"] += 1
            user = TRIGGER_USER
        return EVENT_TEMPLATE % ('10.100.21.' + str(eventId), '10.101.31.' + str(eventId)
                                 , eventId, user, int(time.time() * 1000))

    eventList =  "[" + ", ".join([event(i) for i in range(firstId, firstId+eventCount)]) + "]"
    return (val["tc"], eventList)

def get_ssl_options(host=None):
    cert_dict = {'10.101.59.231': '49bb6435-7920-4a34-8e4a-86f72867c24e',
                 '10.101.59.232': 'f835f7cd-344c-40a8-92d2-fa776d001ff8',
                 '10.101.59.236': '5249e632-eafc-48dc-891f-88cf407e70ec'}
    certs_dir = './ssl/t'
    ssl_options = {'ca_certs': os.path.join(certs_dir, 'ca_crt.pem'),
                   'keyfile': os.path.join(certs_dir, cert_dict[host] + '_key.pem'),
                   'certfile': os.path.join(certs_dir, cert_dict[host] + '.pem'),
                   'cert_reqs': ssl.CERT_REQUIRED,}
    return ssl_options

def main():
    """ Read json transactions from stdin,

        get the user periodicity information and output it
    """

    logging.getLogger('pika').setLevel(logging.INFO)
    options = loadArgs()[0]
    triggerRate = options.triggerpercent / 100.0
    exchange = GLOBAL_EXCHANGE if options.globalengine else LOCAL_EXCHANGE

    sys.stdout.write("\nPublishing %d events (in batches of %s) to %s (%s, %s) on %s\n\n"
                     % (options.number, options.batchsize, options.exchange, exchange['virtualhost'], exchange['type'], options.remotehost))
    sys.stdout.write(" time between sends: %f seconds\n" % (options.sleeptime))
    if options.sleeptime > 0:
        sys.stdout.write("    publishing rate: %d eps\n" % (options.batchsize / options.sleeptime))
    sys.stdout.write("       trigger rate: %d%%\n" % options.triggerpercent)

    credentials = pika.PlainCredentials('guest', 'guest')
    parameters  = pika.ConnectionParameters(host=options.remotehost
                                            , virtual_host=exchange['virtualhost'] , credentials=credentials
                                            , ssl=False, port=5672)
                                            #, ssl_options=get_ssl_options(options.remotehost))

    connection  = pika.BlockingConnection(parameters)
    channel     = connection.channel()
    channel.exchange_declare(exchange=options.exchange, type=exchange['type'], durable=exchange['durable'])
    properties  = pika.spec.BasicProperties(headers=HEADERS)

    sys.stdout.write("         start time: %s\n\n" % time.strftime("%H:%M:%S"))
    start = time.time()
    triggerCount = 0
    sentCount = 0
    # try:
    for j in range(0, options.number, options.batchsize):
        if j%1000 == 0:
            sys.stdout.write("           %s: %d\r" %(time.strftime("%H:%M:%S"), j))
            sys.stdout.flush()

        triggerCount, message = events(j, options.batchsize, triggerCount, triggerRate)
        if options.printonly:
            print(message)
        else:
            channel.basic_publish(exchange=options.exchange, routing_key='', body=message, properties=properties)
        sentCount = j+options.batchsize

        if options.sleeptime > 0:
            time.sleep(options.sleeptime)

    # except KeyboardInterrupt:
    #     pass
    # except Exception as inst:
    #     print("\nException\n  type:", type(inst))
    #     print(" args:", inst.args)
    #     print(inst)
    #     print()

    timetaken = time.time() - start
    stats     = (options.number, triggerCount, timetaken, options.number/timetaken)
    sys.stdout.write("\n           end time: %s\n" % time.strftime("%H:%M:%S"))
    sys.stdout.write("         time taken: %d seconds\n" % int(timetaken))
    sys.stdout.write("             events: %d\n" %  sentCount)
    sys.stdout.write("           triggers: %d\n" % triggerCount)
    sys.stdout.write("                eps: %f\n\n" % (sentCount/timetaken))



if __name__ == '__main__':
    main()
