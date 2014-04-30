SCHEMA = 'universal'
ROOT = _(
    _SYMBOLS=(gacc.Symbols(gacc.Attribute('install_root', gacc.String(), doc='The root directory of the installation.'), gacc.Attribute('domain_name', gacc.String(), doc='The domain of the source web site. This is a default. Further domainNames can be added in ThreatDetection/domains.'), gacc.Attribute('logs_path', gacc.String()), gacc.Attribute('snapshot_path', gacc.String()), gacc.Attribute('reports_path', gacc.String()), gacc.Attribute('certs_cert', gacc.String()), gacc.Attribute('certs_key', gacc.String()), gacc.Attribute('stms_port', gacc.Integer(), doc='Port on which the Silver Tail Messaging Service (STMS) traffic will pass.'), gacc.Attribute('tasks_organizer', gacc.String(), doc='Path to the parent directory of task subdirectories for Organizer.'), gacc.Attribute('tasks_organizer_out', gacc.String(), doc='Path to the directory where Organizer will write completed tasks.'), gacc.Attribute('tasks_indexer', gacc.String(), doc='Path to the parent directory of task subdirectories for Indexer.'), gacc.Attribute('tasks_indexer_out', gacc.String(), doc='Path to the directory where Indexer will write completed tasks.'), gacc.Attribute('tasks_metaindexer', gacc.String(), doc='Path to the parent directory of task subdirectories for MetaIndexer.'), gacc.Attribute('tasks_metaindexer_out', gacc.String(), doc='Path to the directory where MetaIndexer will write completed tasks.'), gacc.Attribute('tasks_reportbuilder', gacc.String(), doc='Path to the parent directory of task subdirectories for ReportBuilder.'), gacc.Attribute('tasks_reportbuilder_out', gacc.String(), doc='Path to the directory where ReportBuilder will write completed tasks.'), gacc.Attribute('tasks_r2b2', gacc.String(), doc='Path to the parent directory of task subdirectories for R2B2.'), gacc.Attribute('tasks_r2b2_out', gacc.String(), doc='Path to the directory where R2B2 will write completed tasks.'), gacc.Attribute('tasks_silversleuth', gacc.String(), doc='Path to the parent directory of task subdirectories for SilverSleuth.'), gacc.Attribute('tasks_silversleuth_out', gacc.String(), doc='Path to the directory where SilverSleuth will write completed tasks.'), gacc.Attribute('tasks_profileupdater', gacc.String(), doc='Path to the parent directory of task subdirectories for Profile Updater.'), gacc.Attribute('tasks_profileupdater_out', gacc.String(), doc='Path to the directory where ProfileUpdater will write completed tasks.'), gacc.Attribute('tasks_final_out', gacc.String(), doc='The final tasks directory. Set the completed directory for the last application in the pipeline to tasks_final_out.'), gacc.Attribute('numBusShardsFront', gacc.Integer(), doc='The number of bus shards used by the Silver Tail Messaging System in the front message bus. '), gacc.Attribute('subscriber_shards_front', gacc.String(), doc='The number of items in the subscriber_shards_front list must match numBusShardsFront. '), gacc.Attribute('numBusShardsBack', gacc.Integer(), doc='The number of bus shards used by the Silver Tail Messaging System in the back message bus. '), gacc.Attribute('subscriber_shards_back', gacc.String(), doc='The number of items in the subscriber_shards_back list must match numBusShardsBack. '), gacc.Attribute('numBusShardsAlert', gacc.Integer(), doc='The number of bus shards used by the Silver Tail Messaging System in the alert message bus. '), gacc.Attribute('subscriber_shards_alert', gacc.String(), doc='The number of items in the subscriber_shards_alert list must match numBusShardsAlert. '), gacc.Attribute('test_binary_name', gacc.String(), doc='QA framework test case property.'), gacc.Attribute('test_case_name', gacc.String(), doc='QA framework test case property.'), gacc.Attribute('test_name', gacc.String(), doc='QA framework test case property.'), gacc.Attribute('test_id', gacc.String(), doc='QA framework test case property.'), gacc.Attribute('module_data_dir', gacc.String(), doc='QA framework test case property.'), gacc.Attribute('test_binary_data_dir', gacc.String(), doc='QA framework test case property.'), gacc.Attribute('test_case_data_dir', gacc.String(), doc='QA framework test case property.'), gacc.Attribute('test_data_dir', gacc.String(), doc='QA framework test case property.'), gacc.Attribute('module_knowngood_dir', gacc.String(), doc='QA framework test case property.'), gacc.Attribute('test_binary_knowngood_dir', gacc.String(), doc='QA framework test case property.'), gacc.Attribute('test_case_knowngood_dir', gacc.String(), doc='QA framework test case property.'), gacc.Attribute('test_knowngood_dir', gacc.String(), doc='QA framework test case property.'), gacc.Attribute('module_out_dir', gacc.String(), doc='QA framework test case property.'), gacc.Attribute('test_binary_out_dir', gacc.String(), doc='QA framework test case property.'), gacc.Attribute('test_case_out_dir', gacc.String(), doc='QA framework test case property.'), gacc.Attribute('test_out_dir', gacc.String(), doc='QA framework test case property.'), gacc.Attribute('conf_path', gacc.String(), doc='QA framework test case property.'), gacc.Attribute('localhostname', gacc.String(), doc='The name of the local host.'), gacc.Attribute('silverplex_host', gacc.String(), doc='The name of the local host.')), _(
        install_root='/var/opt/silvertail'
        , domain_name='silvertailsystems.com'
        , logs_path='/var/opt/silvertail/data/logs'
        , snapshot_path='/var/opt/silvertail/data/snapshot'
        , reports_path='/var/opt/silvertail/data/reports'
        , certs_cert='/var/opt/silvertail/certs/silvertail.crt'
        , certs_key='/var/opt/silvertail/certs/silvertail.key'
        , stms_port=24000
        , tasks_organizer='/var/opt/silvertail/data/tasks/organizer'
        , tasks_organizer_out='/var/opt/silvertail/data/tasks/organizer/completed'
        , tasks_indexer='/var/opt/silvertail/data/tasks/indexer'
        , tasks_indexer_out='/var/opt/silvertail/data/tasks/indexer/completed'
        , tasks_metaindexer='/var/opt/silvertail/data/tasks/metaindexer'
        , tasks_metaindexer_out='/var/opt/silvertail/data/tasks/metaindexer/completed'
        , tasks_reportbuilder='/var/opt/silvertail/data/tasks/reportbuilder'
        , tasks_reportbuilder_out='/var/opt/silvertail/data/tasks/reportbuilder/completed'
        , tasks_r2b2='/var/opt/silvertail/data/tasks/r2b2'
        , tasks_r2b2_out='/var/opt/silvertail/data/tasks/r2b2/completed'
        , tasks_silversleuth='/var/opt/silvertail/data/tasks/silversleuth'
        , tasks_silversleuth_out='/var/opt/silvertail/data/tasks/silversleuth/completed'
        , tasks_profileupdater='/var/opt/silvertail/data/tasks/profileupdater'
        , tasks_profileupdater_out='/var/opt/silvertail/data/tasks/profileupdater/completed'
        , tasks_final_out='/var/opt/silvertail/data/tasks/completed'
        , numBusShardsFront=2
        , subscriber_shards_front='0,1'
        , numBusShardsBack=16
        , subscriber_shards_back='0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15'
        , numBusShardsAlert=16
        , subscriber_shards_alert='0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15'
        , test_binary_name='corganizer_test.py'
        , test_case_name='ConfigTestCase'
        , test_name='test_with_surfer'
        , test_id='corganizer_test.ConfigTestCase.test_with_surfer'
        , module_data_dir='testdata'
        , test_binary_data_dir='testdata/corganizer_test.py'
        , test_case_data_dir='testdata/corganizer_test.py/ConfigTestCase'
        , test_data_dir='testdata/corganizer_test.py/ConfigTestCase/test_with_surfer'
        , module_knowngood_dir='testdata/knowngood'
        , test_binary_knowngood_dir='testdata/corganizer_test.py/knowngood'
        , test_case_knowngood_dir='testdata/corganizer_test.py/ConfigTestCase/knowngood'
        , test_knowngood_dir='testdata/corganizer_test.py/ConfigTestCase/test_with_surfer/knowngood'
        , module_out_dir='o'
        , test_binary_out_dir='o/corganizer_test.py'
        , test_case_out_dir='o/corganizer_test.py/ConfigTestCase'
        , test_out_dir='o/corganizer_test.py/ConfigTestCase/test_with_surfer'
        , conf_path='testdata/corganizer_test.py/universal_conf.py'
        , localhostname='lab6'
        , silverplex_host='lab6'
        ))
    , version=_(
        number='5.0.0.0-1149-g7274424'
        )
    , overlay=[
        _(
            name='stms-front'
            , overrides=_(
                _SYMBOLS=(gacc.Symbols(gacc.Attribute('stms_port', gacc.Integer())), _(
                    stms_port=23000
                    ))
                , audit=_()
                , threatDetection=_(
                    hijackSessionParameters=_()
                    , transitionThreatSeverities=_(
                        linkageThreatSeverities=_()
                        )
                    , transitionThreatParameters=_()
                    )
                , threatScoring=_(
                    anonIpScoring=_()
                    , behaviorScoring=_()
                    , malwareScoring=_()
                    , mitbScoring=_()
                    , mitmScoring=_()
                    , velocityScoring=_()
                    , profileBehaviorScoring=_()
                    )
                , surfer=_(
                    stmsOut=_(
                        numBusShards=gacc.Expr('numBusShardsBack')
                        )
                    )
                , profileUpdater=_(
                    transactionAttributes=_()
                    )
                , silversleuth=_(
                    transactionAttributes=_()
                    )
                , clientanalyzer=_()
                , stms=_(
                    numBusShards=gacc.Expr('numBusShardsFront')
                    )
                , subscribers=_(
                    numBusShards=gacc.Expr('numBusShardsFront')
                    , subscriber=[
                        _(
                            name=gacc.Expr('localhostname')
                            , shards=gacc.Expr('subscriber_shards_front')
                            )
                        ]
                    )
                )
            )
        , _(
            name='stms-back'
            , overrides=_(
                _SYMBOLS=(gacc.Symbols(gacc.Attribute('stms_port', gacc.Integer())), _(
                    stms_port=24000
                    ))
                , audit=_()
                , threatDetection=_(
                    hijackSessionParameters=_()
                    , transitionThreatSeverities=_(
                        linkageThreatSeverities=_()
                        )
                    , transitionThreatParameters=_()
                    )
                , threatScoring=_(
                    anonIpScoring=_()
                    , behaviorScoring=_()
                    , malwareScoring=_()
                    , mitbScoring=_()
                    , mitmScoring=_()
                    , velocityScoring=_()
                    , profileBehaviorScoring=_()
                    )
                , profileUpdater=_(
                    transactionAttributes=_()
                    )
                , silversleuth=_(
                    transactionAttributes=_()
                    )
                , clientanalyzer=_()
                , silverplex=_(
                    httpServerPort='12352'
                    )
                , stms=_(
                    numBusShards=gacc.Expr('numBusShardsBack')
                    )
                , subscribers=_(
                    numBusShards=gacc.Expr('numBusShardsBack')
                    , subscriber=[
                        _(
                            name='lab5'
                            , shards=gacc.Expr('subscriber_shards_back')
                            )
                        ]
                    )
                )
            )
        ]
    , siteClass=[
        _(
            serviceClass=[
                _(
                    program=_(
                        name='SilverCat'
                        , shard='0'
                        )
                    , name='SilverCat'
                    , httpServerPort='127.0.0.1:4446'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='Scout'
                        , shard=gacc.Expr('ROOT.service.host.nickname')
                        )
                    , name='Scout'
                    , httpServerPort='127.0.0.1:4447'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='ScoutProxy'
                        , shard=gacc.Expr('ROOT.service.host.nickname')
                        )
                    , name='ScoutProxy'
                    , hasVarz=False
                    , isHttps=True
                    )
                , _(
                    program=_(
                        name='SysStats'
                        , shard=gacc.Expr('ROOT.service.host.nickname')
                        )
                    , name='SysStats'
                    )
                , _(
                    program=_(
                        name='VarzFetcher'
                        , shard='0'
                        )
                    , name='VarzFetcher'
                    )
                , _(
                    program=_(
                        name='VarzGrapher'
                        , shard='0'
                        )
                    , name='VarzGrapher'
                    )
                , _(
                    program=_(
                        name='SilverPlex'
                        , shard='front'
                        )
                    , name='PlexFront'
                    , overlay='stms-front'
                    )
                , _(
                    program=_(
                        name='SilverSurfer'
                        , shard='0'
                        )
                    , name='SilverSurfer'
                    , overlay='stms-front'
                    )
                , _(
                    program=_(
                        name='SilverPlex'
                        , shard='back'
                        )
                    , name='PlexBack'
                    , overlay='stms-back'
                    , httpServerPort='12352'
                    )
                , _(
                    program=_(
                        name='SilverTap'
                        , shard=gacc.Expr('ROOT.service.host.nickname')
                        )
                    , name='SilverTap'
                    , overlay='stms-front'
                    )
                , _(
                    program=_(
                        name='Organizer'
                        , shard=gacc.Expr('ROOT.service.host.nickname')
                        )
                    , name='Organizer'
                    , overlay='stms-back'
                    )
                , _(
                    program=_(
                        name='COrganizer'
                        , shard=gacc.Expr('ROOT.service.host.nickname')
                        )
                    , name='COrganizer'
                    , overlay='stms-back'
                    )
                , _(
                    program=_(
                        name='SilverSleuth'
                        , shard='0'
                        )
                    , name='SilverSleuth'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='ProfileUpdater'
                        , shard='0'
                        )
                    , name='ProfileUpdater'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='ReportBuilder'
                        , shard='0'
                        )
                    , name='ReportBuilder'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='R2B2'
                        , shard='0'
                        )
                    , name='R2B2'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='Indexer'
                        , shard='0'
                        )
                    , name='Indexer'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='MetaIndexer'
                        , shard='0'
                        )
                    , name='MetaIndexer'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='UIServer'
                        , shard='0'
                        )
                    , name='UIServer'
                    , httpServerPort='22345'
                    )
                , _(
                    program=_(
                        name='AnnoDb'
                        , shard='0'
                        )
                    , name='AnnoDb'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='SiteProxy'
                        , shard='0'
                        )
                    , name='SiteProxy'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='Mitigator'
                        , shard='0'
                        )
                    , name='Mitigator'
                    , overlay='stms-back'
                    )
                , _(
                    program=_(
                        name='ActionServer'
                        , shard='0'
                        )
                    , name='ActionServer'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='FilePusher'
                        , shard='0'
                        )
                    , name='FilePusher'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='SiteMinderProxy'
                        , shard='0'
                        )
                    , name='SiteMinderProxy'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='Distributor'
                        , shard='0'
                        )
                    , name='Distributor'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='AlertServer'
                        , shard='0'
                        )
                    , name='AlertServer'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='SilverPlex'
                        , shard='alert'
                        )
                    , name='PlexAlert'
                    , overlay='stms-alert'
                    , httpServerPort='12357'
                    )
                , _(
                    program=_(
                        name='IncidentServer'
                        , shard='0'
                        )
                    , name='IncidentServer'
                    , overlay='stms-alert'
                    , httpServerPort='12356'
                    )
                , _(
                    program=_(
                        name='VarzCache'
                        , shard='0'
                        )
                    , name='VarzCache'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='TaskScheduler'
                        , shard='0'
                        )
                    , name='TaskScheduler'
                    )
                , _(
                    program=_(
                        name='CProfileUpdater'
                        , shard=gacc.Expr('ROOT.service.host.nickname')
                        )
                    , name='CProfileUpdater'
                    , overlay='stms-back'
                    )
                ]
            , serviceGroup=[
                _(
                    name='common'
                    , serviceClasses='Scout, ScoutProxy, SysStats'
                    )
                , _(
                    name='varz'
                    , serviceClasses='SiteProxy, SilverCat, VarzFetcher, VarzGrapher, VarzCache'
                    )
                , _(
                    name='publisher-node'
                    , serviceClasses='PlexBack'
                    , childGroups='common, varz'
                    )
                , _(
                    name='surfer-publisher-node'
                    , serviceClasses='PlexFront, SilverSurfer, PlexBack'
                    , childGroups='common, varz'
                    )
                , _(
                    name='cprofileupdater'
                    , serviceClasses='CProfileUpdater'
                    , childGroups='common'
                    )
                ]
            , machineClass=[
                _(
                    name='publisher-node'
                    , serviceGroup='publisher-node'
                    )
                , _(
                    name='surfer-publisher-node'
                    , serviceGroup='surfer-publisher-node'
                    )
                , _(
                    name='cprofileupdater'
                    , serviceGroup='cprofileupdater'
                    )
                , _(
                    name='cassandra-node'
                    , serviceGroup='common'
                    )
                , _(
                    name='idle-node'
                    , serviceGroup='common'
                    )
                ]
            )
        ]
    , site=_(
        host=[
            _(
                name=gacc.Expr('localhostname')
                , machineClass='surfer-publisher-node'
                )
            , _(
                name='lab5'
                , machineClass='cprofileupdater'
                )
            , _(
                name='lab9'
                , machineClass='cassandra-node'
                )
            , _(
                name='lab8'
                , machineClass='idle-node'
                )
            ]
        )
    , service=_(
        id='<service.id>'
        , nickname='<service.nickname>'
        , overlays='<service.overlays>'
        , domain='<service.domain>'
        , host=_(
            name='<service.host.name>'
            , nickname='<service.host.nickname>'
            , machineClass='<service.host.machineClass>'
            , overlay='<service.host.overlay>'
            )
        , machineClass=_(
            name='<service.machineClass.name>'
            , serviceGroup='<service.machineClass.serviceGroup>'
            , overlay='<service.machineClass.overlay>'
            )
        , serviceClass=_(
            program=_(
                name='<service.serviceClass.program.name>'
                , shard='<service.serviceClass.program.shard>'
                )
            , name='<service.serviceClass.name>'
            , nickname='<service.serviceClass.nickname>'
            , overlay='<service.serviceClass.overlay>'
            , httpServerPort='<service.serviceClass.httpServerPort>'
            , varzUrl='<service.serviceClass.varzUrl>'
            )
        , varzMonitorUrl='<service.varzMonitorUrl>'
        )
    , varz=_(
        rrdRoot=gacc.Expr("install_root + '/rrd'")
        , authCredFile='/var/opt/silvertail/etc/varzfetcher-internal.ecred'
        , endpoint=[
            _(
                program=_(
                    name='SysStats'
                    , shard=gacc.Expr('localhostname')
                    )
                , host=gacc.Expr('localhostname')
                , authType='basic'
                , url=gacc.Expr("'https://%s:4448/srv/sysstats/%s/varz' % (localhostname, localhostname)")
                , nickname=gacc.Expr("'SysStats-%s' % localhostname")
                )
            , _(
                program=_(
                    name='VarzFetcher'
                    , shard='0'
                    )
                , host=gacc.Expr('localhostname')
                , authType='basic'
                , url=gacc.Expr("'https://%s:4448/srv/varzfetcher/0/varz' % localhostname")
                , nickname='VarzFetcher-0'
                )
            , _(
                program=_(
                    name='VarzGrapher'
                    , shard='0'
                    )
                , host=gacc.Expr('localhostname')
                , authType='basic'
                , url=gacc.Expr("'https://%s:4448/srv/varzgrapher/0/varz' % localhostname")
                , nickname='VarzGrapher-0'
                )
            , _(
                program=_(
                    name='SysStats'
                    , shard='lab5'
                    )
                , host='lab5'
                , url='https://lab5:4448/srv/sysstats/lab5/varz'
                , nickname='SysStats-lab5'
                )
            , _(
                program=_(
                    name='SilverPlex'
                    , shard='back'
                    )
                , host=gacc.Expr('localhostname')
                , authType='basic'
                , url=gacc.Expr("'https://%s:4448/srv/silverplex/back/varz' % localhostname")
                , nickname='SilverPlex-back'
                )
            , _(
                program=_(
                    name='CProfileUpdater'
                    , shard='lab5'
                    )
                , host='lab5'
                , url='https://lab5:4448/srv/cprofileupdater/lab5/varz'
                , nickname='CProfileUpdater-lab5'
                )
            , _(
                program=_(
                    name='Cassandra'
                    , shard='lab9'
                    )
                , host='lab9'
                , url='http://lab9:7778/varz'
                , nickname='Cassandra-lab9'
                )
            , _(
                program=_(
                    name='SysStats'
                    , shard='lab9'
                    )
                , host='lab9'
                , url='https://lab9:4448/srv/sysstats/lab9/varz'
                , nickname='SysStats-lab9'
                )
            , _(
                program=_(
                    name='SilverPlex'
                    , shard='front'
                    )
                , host=gacc.Expr('localhostname')
                , authType='basic'
                , url=gacc.Expr("'https://%s:4448/srv/silverplex/front/varz' % localhostname")
                , nickname='SilverPlex-front'
                )
            , _(
                program=_(
                    name='SilverSurfer'
                    , shard='0'
                    )
                , host=gacc.Expr('localhostname')
                , authType='basic'
                , url=gacc.Expr("'https://%s:4448/srv/silversurfer/0/varz' % localhostname")
                , nickname='SilverSurfer-0'
                )
            ]
        )
    , reports=_(
        rootDir=gacc.Expr('logs_path')
        , reportsDir=gacc.Expr('reports_path')
        , mitigator_rules=gacc.Expr("install_root + '/etc/mitigator.rules'")
        , reportbuilder_rules=gacc.Expr("install_root + '/etc/reportbuilder.rules'")
        , ruleTags=gacc.Expr("install_root + '/etc/Tags.json'")
        , balReportConf=gacc.Expr("install_root + '/etc/balReport.reportconf'")
        , report=[
            _(
                name='IP'
                )
            , _(
                name='User'
                )
            , _(
                name='Page'
                )
            , _(
                name='Threat'
                )
            ]
        )
    , multitenancy=_(
        enabled=True
        , tenancyGlobal=True
        , rulesRootPath='/var/opt/silvertail/etc/rules/'
        , balReportConfsPath='/var/opt/silvertail/etc/balreports'
        , edsPath='/var/opt/silvertail/data/eds/ipTenancy.eds'
        )
    , admin=_(
        unprivilegedUser='silvertail'
        , nReadThreads=1
        , nThreads=1
        , suffix='.log.gz'
        , ipGeoDB=gacc.Expr("install_root + '/lib/GeoLiteCity.dat'")
        , logsPerTopicBits=4
        , ignorePriority=True
        , alertSpoolDirectory='/var/opt/silvertail/data/alerts'
        , scoreletFileName='/var/opt/silvertail/etc/scoreletmanifest.eds'
        )
    , audit=_()
    , authentication=_(
        strongPasswords=True
        , logins='st'
        , fails=10
        )
    , scout=_(
        httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
        , confDir=gacc.Expr("install_root + '/etc/conf.d'")
        , htpasswdFile='/var/opt/silvertail/etc/silvercat.htpasswd'
        )
    , cat=_(
        confPath=gacc.Expr("install_root + '/etc/universal_conf.py'")
        , httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
        , certsAuditTrailFile='/var/log/silvertail/certs.audit'
        )
    , threatDetection=_(
        hostnames=[
            _(
                name=gacc.Expr('domain_name')
                )
            , _(
                name=gacc.Expr("'www.%s' % domain_name")
                )
            ]
        , hijackSessionParameters=_()
        , transitionThreatSeverities=_(
            linkageThreatSeverities=_()
            )
        , transitionThreatParameters=_()
        )
    , threatScoring=_(
        anonIpScoring=_()
        , behaviorScoring=_()
        , malwareScoring=_()
        , mitbScoring=_()
        , mitmScoring=_()
        , velocityScoring=_()
        , profileBehaviorScoring=_()
        )
    , uiserver=_(
        httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
        , makeCertPath=gacc.Expr("install_root + '/bin/makecert.sh'")
        , incidentServer=_()
        )
    , mitigator=_(
        registerPersistenceDir=gacc.Expr("install_root + '/data/mitregisters'")
        , httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
        , pruneAttributes='next-guid, guid-out'
        , stmsAlertsOut=_(
            numBusShards=gacc.Expr('numBusShardsAlert')
            , serverPort=gacc.Expr("'%s:%d' % (silverplex_host, 26000)")
            , tls=_(
                x509=[
                    _(
                        cert=gacc.Expr('certs_cert')
                        , key=gacc.Expr('certs_key')
                        )
                    ]
                , tlsTrusted=_(
                    x509=[
                        _(
                            cert=gacc.Expr('certs_cert')
                            )
                        ]
                    )
                )
            )
        )
    , procstats=[
        _(
            httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
            )
        ]
    , carrera=_(
        nThreads=1
        )
    , speedster=_(
        nReadThreads=1
        , nThreads=1
        )
    , sysstats=_(
        httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
        , blockDevices='dm-0'
        )
    , varzmonitor=_(
        httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
        )
    , varzfetcher=_(
        httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
        )
    , varzgrapher=_(
        httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
        , localSnapshotPort=4445
        )
    , surfer=_(
        httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
        , stmsOut=_(
            serverPort=gacc.Expr("'%s:%d' % (silverplex_host, 24000)")
            , tls=_(
                x509=[
                    _(
                        cert=gacc.Expr('certs_cert')
                        , key=gacc.Expr('certs_key')
                        )
                    ]
                , tlsTrusted=_(
                    x509=[
                        _(
                            cert=gacc.Expr('certs_cert')
                            )
                        ]
                    )
                )
            )
        , earlyPool=_(
            numThreads=8
            )
        , sleuthUserPool=_()
        , sleuthIpPool=_()
        , sleuthPagePool=_()
        , sleuthParameterPool=_()
        , autoTuningPool=_(
            enable=True
            , persistentPath=gacc.Expr("install_root + '/data/autotune.conf'")
            )
        , guidUserMap=_(
            guidIn='guid'
            , guidOut='guid-out'
            , prevGuidOut='prev-guid-out'
            , userOut='user-out'
            , persistPeriodSecs=60
            , persistDir=gacc.Expr("install_root + '/data/guiduser'")
            , login=[
                _(
                    _SUBTYPE='fromTxn'
                    , urlpath='/login'
                    , page='page'
                    , user='user-from-login'
                    )
                ]
            , guidFollower=[
                _(
                    current='guid'
                    , next='next-guid'
                    )
                ]
            )
        , glossary=[
            _(
                id='cookies'
                , type='COOKIE'
                , delimiters=';'
                )
            , _(
                id='args'
                , type='ARGS'
                )
            ]
        , datamodel=_(
            shelfLifeHours=1.0
            , decayPeriodHours=0.0
            )
        , analysisWindow=_(
            decayPeriodHours=0.0
            )
        , sleuthUserThreatScores=_(
            threatScoring=_(
                enabled=True
                , transactionAttributes=_()
                )
            , scoreAttributes=_()
            , periodicity=_()
            )
        , sleuthIpThreatScores=_(
            threatScoring=_(
                enabled=True
                , transactionAttributes=_()
                )
            , scoreAttributes=_()
            , periodicity=_()
            )
        , sleuthPageThreatScores=_(
            threatScoring=_(
                enabled=True
                , transactionAttributes=_()
                )
            , scoreAttributes=_()
            )
        , sleuthParameterThreatScores=_(
            threatScoring=_(
                enabled=True
                , transactionAttributes=_()
                )
            , scoreAttributes=_()
            )
        )
    , incidentServer=_(
        httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
        , incidentPool=_()
        , incident=_()
        , incidentEmail=_()
        )
    , cOrganizer=_(
        httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
        , shardingPool=_(
            numThreads=4
            )
        , cOrganizerPool=_(
            numThreads=16
            )
        )
    , cProfileUpdater=_(
        httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
        , txnsPerScanner=100000
        , userProfileId='baseuser'
        , shardingPool=_()
        , cProfileUpdaterPool=_(
            numThreads=16
            )
        )
    , organizer=_(
        httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
        , tasks=_(
            completed=gacc.Expr('tasks_organizer_out')
            )
        )
    , indexer=_(
        nThreads=1
        , tasks=_(
            pending=gacc.Expr('tasks_organizer_out')
            , inProcess=gacc.Expr("tasks_indexer + '/in_process'")
            , failed=gacc.Expr("tasks_indexer + '/failed'")
            , completed=gacc.Expr('tasks_indexer_out')
            )
        )
    , metaindexer=_(
        nThreads=1
        , tasks=_(
            pending='disabled'
            , inProcess=gacc.Expr("tasks_metaindexer + '/in_process'")
            , failed=gacc.Expr("tasks_metaindexer + '/failed'")
            , completed=gacc.Expr('tasks_metaindexer_out')
            )
        )
    , database=_(
        dbhost=gacc.Expr('localhostname')
        , dbport=7078
        , dbname='silvertail'
        , dbuser='silvertail'
        , dbpasswd='silvertail'
        )
    , cassandraClient=_(
        host='lab9'
        , keyspace='silvertail_sears_mt'
        )
    , profileSampler=_(
        transactionAttributes=_()
        , nThreads=1
        )
    , profileUpdater=_(
        transactionAttributes=_()
        , nThreads=1
        , tasks=_(
            pending=gacc.Expr('tasks_indexer_out')
            , inProcess=gacc.Expr("tasks_profileupdater + '/in_process'")
            , failed=gacc.Expr("tasks_profileupdater + '/failed'")
            , completed=gacc.Expr('tasks_profileupdater_out')
            )
        )
    , reportbuilder=_(
        nReadThreads=1
        , nThreads=1
        , benignClusters=gacc.Expr("install_root + '/benignclusters.json'")
        , tasks=_(
            pending=gacc.Expr('tasks_profileupdater_out')
            , inProcess=gacc.Expr("tasks_r2b2 + '/in_process'")
            , failed=gacc.Expr("tasks_r2b2 + '/failed'")
            , completed=gacc.Expr('tasks_final_out')
            )
        )
    , silversleuth=_(
        transactionAttributes=_()
        , nThreads=1
        , tasks=_(
            pending=gacc.Expr('tasks_indexer_out')
            , inProcess=gacc.Expr("tasks_silversleuth + '/in_process'")
            , failed=gacc.Expr("tasks_silversleuth + '/failed'")
            , completed=gacc.Expr('tasks_silversleuth_out')
            )
        )
    , clientanalyzer=_(
        nThreads=1
        )
    , silverplex=_(
        httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
        , stmsServerPort=gacc.Expr('stms_port')
        , maxSessions=100
        , tls=_(
            x509=[
                _(
                    cert=gacc.Expr('certs_cert')
                    , key=gacc.Expr('certs_key')
                    )
                ]
            , tlsTrusted=_(
                x509=[
                    _(
                        cert=gacc.Expr('certs_cert')
                        )
                    ]
                )
            )
        )
    , alertServer=_(
        httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
        )
    , stms=_(
        channel=[
            _(
                serverPort=gacc.Expr("'%s:%d' % (silverplex_host, stms_port)")
                )
            ]
        , tls=_(
            x509=[
                _(
                    cert=gacc.Expr('certs_cert')
                    , key=gacc.Expr('certs_key')
                    )
                ]
            , tlsTrusted=_(
                x509=[
                    _(
                        cert=gacc.Expr('certs_cert')
                        )
                    ]
                )
            )
        )
    , schema=_(
        attribute=[
            _(
                _SUBTYPE='atomic.ordinary'
                , id='tenant'
                , required=True
                , type='REQUEST'
                , name='tenant'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='baseuser'
                , required=True
                , type='USER'
                , name='id'
                , percentDecode=True
                )
            , _(
                _SUBTYPE='concat'
                , id='user'
                , main='tenant'
                , suffix='baseuser'
                , suffixRequired=True
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='pagebase'
                , required=True
                , type='REQUEST'
                , name='page'
                , trim=True
                , trimChar=';'
                , maxlen=64
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='ip'
                , required=True
                , class_='t'
                , type='STTX'
                , name='ip'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='command'
                , type='ARGS'
                , name='command'
                , maxlen=64
                )
            , _(
                _SUBTYPE='concat'
                , id='page'
                , required=True
                , main='pagebase'
                , suffix='command'
                )
            , _(
                _SUBTYPE='pair'
                , id='user-ip'
                , first='user'
                , second='ip'
                , allowempty='first'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='agent'
                , type='HEADERS'
                , name='user-agent'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='refer'
                , type='HEADERS'
                , name='referer'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='host'
                , type='HEADERS'
                , name='host'
                )
            , _(
                _SUBTYPE='prev'
                , id='prev-page'
                , prevId='page'
                )
            , _(
                _SUBTYPE='pair'
                , id='bigram'
                , first='prev-page'
                , second='page'
                )
            , _(
                _SUBTYPE='prev'
                , id='prev-bigram'
                , prevId='bigram'
                )
            , _(
                _SUBTYPE='click'
                , id='click-bucket'
                , outoforder='outoforderclick'
                , bucket=[
                    _(
                        name='subhalfsecondclick'
                        , millis=500
                        )
                    , _(
                        name='sub1secondclick'
                        , millis=1000
                        )
                    , _(
                        name='sub3secondclick'
                        , millis=3000
                        )
                    , _(
                        name='sub5secondclick'
                        , millis=5000
                        )
                    , _(
                        name='sub10secondclick'
                        , millis=10000
                        )
                    , _(
                        name='normalclick'
                        )
                    ]
                )
            , _(
                _SUBTYPE='pair'
                , id='colored-page'
                , first='page'
                , second='click-bucket'
                )
            , _(
                _SUBTYPE='pair'
                , id='colored-bigram'
                , first='prev-page'
                , second='colored-page'
                )
            , _(
                _SUBTYPE='changed'
                , id='ipstatus'
                , changedId='ip'
                )
            , _(
                _SUBTYPE='pair'
                , id='ip-page'
                , first='ip'
                , second='page'
                )
            , _(
                _SUBTYPE='pair'
                , id='user-page'
                , first='user'
                , second='page'
                )
            , _(
                _SUBTYPE='changed'
                , id='agentstatus'
                , changedId='agent'
                )
            , _(
                _SUBTYPE='pair'
                , id='ip-agentstatus'
                , first='ipstatus'
                , second='agentstatus'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='incidentName'
                , type='INCIDENT'
                , name='name'
                , caseSensitive=True
                , percentDecode=True
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='incidentCategory'
                , type='INCIDENT'
                , name='category'
                , caseSensitive=True
                , percentDecode=True
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='incidentDetails'
                , type='INCIDENT'
                , name='details'
                , caseSensitive=True
                , percentDecode=True
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='incidentPriority'
                , type='INCIDENT'
                , name='priority'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='incidentSource'
                , type='INCIDENT'
                , name='source'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='incidentRule'
                , type='ALERT'
                , name='ruleName'
                , caseSensitive=True
                , percentDecode=True
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='incidentRuleComment'
                , type='ALERT'
                , name='ruleComment'
                , caseSensitive=True
                , percentDecode=True
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='status'
                , type='STATUS'
                , name='val'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='accept_encoding'
                , type='HEADERS'
                , name='accept-encoding'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='qst0'
                , type='COOKIE'
                , name='_qSt0'
                , delimiters=';'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='qst1'
                , type='COOKIE'
                , name='_qSt1'
                , delimiters=';'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='janndam'
                , type='COOKIE'
                , name='JannDam'
                , delimiters=';'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='nmref'
                , type='COOKIE'
                , name='nmref'
                , delimiters=';'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='connectiontick'
                , type='TCPCXN'
                , name='pcapTick100us'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='requesttick'
                , type='TCPREQ'
                , name='pcapTick100us'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='guid-out'
                , type='USER'
                , name='guid'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='prev-guid-out'
                , type='USER'
                , name='prev-guid'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='user-out'
                , type='USER'
                , name='id'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='guid'
                , type='COOKIE'
                , name='JSESSIONID'
                , delimiters=';'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='next-guid'
                , type='SETCOOKIE'
                , name='JSESSIONID'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='user-from-login'
                , type='ARGS'
                , name='email'
                )
            ]
        , key=[
            _(
                name='user-ip'
                , id='user-ip'
                , val=[
                    _(
                        id='click-bucket'
                        )
                    , _(
                        id='page'
                        )
                    , _(
                        id='agent'
                        )
                    , _(
                        id='bigram'
                        )
                    , _(
                        id='colored-page'
                        )
                    , _(
                        id='colored-bigram'
                        )
                    , _(
                        id='tenant'
                        )
                    ]
                )
            , _(
                name='ip'
                , id='ip'
                , val=[
                    _(
                        id='click-bucket'
                        )
                    , _(
                        id='user'
                        , allowempty='true'
                        )
                    , _(
                        id='page'
                        )
                    , _(
                        id='agent'
                        )
                    ]
                )
            , _(
                name='user'
                , id='user'
                , val=[
                    _(
                        id='click-bucket'
                        )
                    , _(
                        id='ip'
                        )
                    , _(
                        id='page'
                        )
                    , _(
                        id='agent'
                        )
                    ]
                )
            , _(
                name='page'
                , id='page'
                )
            , _(
                name='user-page'
                , id='user-page'
                , val=[
                    _(
                        id='click-bucket'
                        )
                    , _(
                        id='page'
                        )
                    , _(
                        id='agent'
                        )
                    , _(
                        id='bigram'
                        )
                    , _(
                        id='colored-page'
                        )
                    , _(
                        id='colored-bigram'
                        )
                    ]
                )
            , _(
                name='ip-page'
                , id='ip-page'
                , val=[
                    _(
                        id='click-bucket'
                        )
                    , _(
                        id='page'
                        )
                    , _(
                        id='agent'
                        )
                    , _(
                        id='bigram'
                        )
                    , _(
                        id='colored-page'
                        )
                    , _(
                        id='colored-bigram'
                        )
                    ]
                )
            , _(
                name='agent'
                , id='agent'
                , val=[
                    _(
                        id='ip'
                        )
                    , _(
                        id='user'
                        )
                    ]
                )
            , _(
                name='refer'
                , id='refer'
                )
            ]
        , Index=[
            _(
                name='ip'
                , id='ip'
                , mod=500000
                )
            , _(
                name='user'
                , id='user'
                , mod=500000
                )
            , _(
                name='page'
                , id='page'
                , mod=500000
                )
            , _(
                name='agent'
                , id='agent'
                , mod=500000
                )
            , _(
                name='refer'
                , id='refer'
                , mod=500000
                )
            ]
        , privilege=_()
        )
    , silvertap=_(
        vmLimitMb=6000
        , rssLimitMb=3000
        , httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
        , nThreads=1
        , sslSessionIdTimeoutSeconds=14400
        , sslSessionPersistPeriodSecs=60
        , sslSessionPersistPath=gacc.Expr("install_root + '/data/sslcache'")
        , input=_(
            devices='eth0'
            )
        , filter=_(
            expression='tcp and (port 80 or port 443)'
            )
        , scrub=[
            _(
                type='postargs'
                , default='permissive'
                , hash=[
                    _(
                        name='password'
                        , nibs=13
                        )
                    ]
                )
            ]
        , tls=_(
            x509Dir=_(
                path=gacc.Expr("install_root + '/certs/website'")
                , salt='OT0RN76CRW'
                )
            )
        , ignoreExt=_(
            ext=[
                _(
                    value='.jpg'
                    )
                , _(
                    value='.gif'
                    )
                , _(
                    value='.png'
                    )
                , _(
                    value='.css'
                    )
                , _(
                    value='.ico'
                    )
                , _(
                    value='.js'
                    )
                , _(
                    value='.swf'
                    )
                , _(
                    value='.json'
                    )
                ]
            )
        , includedResponseHeaders=_(
            headerNames='location,content-length'
            )
        )
    , tls=_(
        x509=[
            _(
                cert=gacc.Expr('certs_cert')
                , key=gacc.Expr('certs_key')
                )
            ]
        , tlsTrusted=_(
            x509=[
                _(
                    cert=gacc.Expr('certs_cert')
                    )
                ]
            )
        )
    , logger=_(
        priority='ERR'
        , facility='user'
        , context=gacc.Expr('ROOT.service.serviceClass.program.shard')
        )
    , actionserver=_(
        syslog=[
            _(
                priority='INFO'
                )
            ]
        , webaction=[
            _()
            ]
        , emailaction=[
            _(
                emailParameters=_()
                )
            ]
        )
    , siteMinderProxy=_(
        nThreads=1
        )
    , datasnapshot=_(
        logscrub=_(
            generate=[
                _()
                ]
            , scrub=[
                _(
                    type='any'
                    , default='restrictive'
                    , separators='&'
                    , defaultNibbles=0
                    , allow=[
                        _(
                            name='ip'
                            )
                        , _(
                            name='page'
                            )
                        , _(
                            name='referer'
                            )
                        , _(
                            name='user-agent'
                            )
                        ]
                    )
                , _(
                    type='postargs'
                    , default='restrictive'
                    , separators='&'
                    , defaultNibbles=0
                    )
                , _(
                    type='getargs'
                    , default='restrictive'
                    , separators='&'
                    , defaultNibbles=0
                    )
                , _(
                    type='cookies'
                    , default='restrictive'
                    , separators=';'
                    , defaultNibbles=0
                    )
                ]
            )
        , tls=_(
            x509=[
                _(
                    cert=gacc.Expr('certs_cert')
                    )
                ]
            )
        )
    , snapshot=_(
        snapshotDir=gacc.Expr('snapshot_path')
        )
    )
