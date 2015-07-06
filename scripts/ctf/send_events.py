#! /usr/bin/env python
# python/asoc9115/send_events.py

""" publish events to rabbitmq

    Events are published in batches
    Events can be "normal" or "trigger".
       The values of their "user_dst" field are "normal" and "Slaarty Baardfast", respectively.
    For all events, the "event_source_id" field takes values "0", "1", "2", ...
"""

import sys
import json
import optparse
import pika
import time

# EVENT_TEMPLATE  = """{"event_source_id":"%d", "ec_activity": "Logon", "user_dst": "%s",  "ec_outcome": "Failure", "esa_time": %d }"""
EVENT_TEMPLATE  = """{"ip_src": "%s", "ip_dst": "%s", "id":"%d", "ec_activity": "Logon", "user_dst": "%s",  "ec_outcome": "Failure", "esa_time": %d }"""
NORMAL_USER     = "normal"
TRIGGER_USER    = "Slaarty Baardfast"
HEADERS         = {'esa.event.type':'Event'}
GLOBAL_EXCHANGE = {'virtualhost': '/rsa/esa', 'durable': True, 'type': 'direct'}
LOCAL_EXCHANGE  = {'virtualhost': '/rsa/sa', 'durable': False, 'type': 'headers'}


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
    def event(eventId):
        user = NORMAL_USER
        if val["tc"] <= i * triggerrate:
            val["tc"] += 1
            user = TRIGGER_USER
        return EVENT_TEMPLATE % ('10.100.21.' + str(eventId), '10.101.31.' + str(eventId)
                                 , eventId, user, int(time.time() * 1000))

    eventList =  "[" + ", ".join([event(i) for i in range(firstId, firstId+eventCount)]) + "]"
    return (val["tc"], eventList)

def main():
    """ Read json transactions from stdin,
        get the user periodicity information and output it
    """

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
    parameters  = pika.ConnectionParameters(host=options.remotehost, virtual_host=exchange['virtualhost'], credentials=credentials)
    connection  = pika.BlockingConnection(parameters)
    channel     = connection.channel()
    channel.exchange_declare(exchange=options.exchange, type=exchange['type'], durable=exchange['durable'])
    properties  = pika.spec.BasicProperties(headers=HEADERS)

    sys.stdout.write("         start time: %s\n\n" % time.strftime("%H:%M:%S"))
    start = time.time()
    triggerCount = 0
    sentCount = 0
    try:
        for i in range(0, options.number, options.batchsize):
            if i%1000 == 0:
                sys.stdout.write("           %s: %d\r" %(time.strftime("%H:%M:%S"), i))
                sys.stdout.flush()

            triggerCount, message = events(i, options.batchsize, triggerCount, triggerRate)
            if options.printonly:
                print message
            else:
                channel.basic_publish(exchange=options.exchange, routing_key='', body=message, properties=properties)
            sentCount = i+options.batchsize

            if options.sleeptime > 0:
                time.sleep(options.sleeptime)

    except KeyboardInterrupt:
        pass
    except Exception as inst:
        print "\nException\n  type:", type(inst)
        print " args:", inst.args
        print inst
        print

    timetaken = time.time() - start
    stats     = (options.number, triggerCount, timetaken, options.number/timetaken)
    sys.stdout.write("\n           end time: %s\n" % time.strftime("%H:%M:%S"))
    sys.stdout.write("         time taken: %d seconds\n" % int(timetaken))
    sys.stdout.write("             events: %d\n" %  sentCount)
    sys.stdout.write("           triggers: %d\n" % triggerCount)
    sys.stdout.write("                eps: %f\n\n" % (sentCount/timetaken))



if __name__ == '__main__':
    main()
