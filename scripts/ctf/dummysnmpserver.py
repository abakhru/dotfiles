#!/usr/bin/env python

import sys

from pysnmp.entity import engine, config
from pysnmp.entity.rfc3413 import cmdrsp, context
from pysnmp.carrier.asynsock.dgram import udp
from pysnmp.smi import instrum, error
from pysnmp.proto.api import v2c

snmpEngine = engine.SnmpEngine()

config.addSocketTransport(
    snmpEngine,
    udp.domainName,
    udp.UdpTransport().openServerMode(('127.0.0.1', 1161))
)

config.addV1System(snmpEngine, 'my-area', 'public', contextName='my-context')

config.addVacmUser(snmpEngine, 2, 'my-area', 'noAuthNoPriv', (1,3,6), (1,3,6))

snmpContext = context.SnmpContext(snmpEngine)

class FileInstrumController(instrum.AbstractMibInstrumController):
    def readVars(self, vars, acInfo=(None, None)):
        try:
            return [ (o,v2c.OctetString(open('/tmp/%s.txt' % o, 'r').read())) for o,v in vars ]
        except IOError:
            raise error.SmiError

    def writeVars(self, vars, acInfo=(None, None)):
        try:
            for o,v in vars:
                open('/tmp/%s.txt' % o, 'w').write(str(v))
            return vars
        except IOError:
            raise error.SmiError

snmpContext.registerContextName(
    v2c.OctetString('my-context'),          # Context Name
    FileInstrumController()                 # Management Instrumentation
)

cmdrsp.GetCommandResponder(snmpEngine, snmpContext)
cmdrsp.SetCommandResponder(snmpEngine, snmpContext)

snmpEngine.transportDispatcher.jobStarted(1)

try:
    snmpEngine.transportDispatcher.runDispatcher()
except:
    snmpEngine.transportDispatcher.closeDispatcher()
    raise
