SCHEMA = 'universal'
ROOT = _(
    _SYMBOLS=(gacc.Symbols(gacc.Attribute('install_root', gacc.String(), doc='The root directory of the installation.'), gacc.Attribute('localhostname', gacc.String(), doc='The name of the local host.'), gacc.Attribute('domain_name', gacc.String(), doc='The domain of the source web site. This is a default. Further domainNames can be added in ThreatDetection/domains.'), gacc.Attribute('logs_path', gacc.String()), gacc.Attribute('snapshot_path', gacc.String()), gacc.Attribute('reports_path', gacc.String()), gacc.Attribute('certs_cert', gacc.String()), gacc.Attribute('certs_key', gacc.String()), gacc.Attribute('silverplex_host', gacc.String(), doc='Network name of the host where SilverPlex service runs.'), gacc.Attribute('stms_port', gacc.Integer(), doc='Port on which the Silver Tail Messaging Service (STMS) traffic will pass.'), gacc.Attribute('tasks_organizer', gacc.String(), doc='Path to the parent directory of task subdirectories for Organizer.'), gacc.Attribute('tasks_organizer_out', gacc.String(), doc='Path to the directory where Organizer will write completed tasks.'), gacc.Attribute('tasks_indexer', gacc.String(), doc='Path to the parent directory of task subdirectories for Indexer.'), gacc.Attribute('tasks_indexer_out', gacc.String(), doc='Path to the directory where Indexer will write completed tasks.'), gacc.Attribute('tasks_metaindexer', gacc.String(), doc='Path to the parent directory of task subdirectories for MetaIndexer.'), gacc.Attribute('tasks_metaindexer_out', gacc.String(), doc='Path to the directory where MetaIndexer will write completed tasks.'), gacc.Attribute('tasks_reportbuilder', gacc.String(), doc='Path to the parent directory of task subdirectories for ReportBuilder.'), gacc.Attribute('tasks_reportbuilder_out', gacc.String(), doc='Path to the directory where ReportBuilder will write completed tasks.'), gacc.Attribute('tasks_r2b2', gacc.String(), doc='Path to the parent directory of task subdirectories for R2B2.'), gacc.Attribute('tasks_r2b2_out', gacc.String(), doc='Path to the directory where R2B2 will write completed tasks.'), gacc.Attribute('tasks_silversleuth', gacc.String(), doc='Path to the parent directory of task subdirectories for SilverSleuth.'), gacc.Attribute('tasks_silversleuth_out', gacc.String(), doc='Path to the directory where SilverSleuth will write completed tasks.'), gacc.Attribute('tasks_profileupdater', gacc.String(), doc='Path to the parent directory of task subdirectories for Profile Updater.'), gacc.Attribute('tasks_profileupdater_out', gacc.String(), doc='Path to the directory where ProfileUpdater will write completed tasks.'), gacc.Attribute('tasks_final_out', gacc.String(), doc='The final tasks directory. Set the completed directory for the last application in the pipeline to tasks_final_out.'), gacc.Attribute('numBusShardsFront', gacc.Integer(), doc='The number of bus shards used by the Silver Tail Messaging System in the front message bus. '), gacc.Attribute('subscriber_shards_front', gacc.String(), doc='The number of items in the subscriber_shards_front list must match numBusShardsFront. '), gacc.Attribute('numBusShardsBack', gacc.Integer(), doc='The number of bus shards used by the Silver Tail Messaging System in the back message bus. '), gacc.Attribute('subscriber_shards_back', gacc.String(), doc='The number of items in the subscriber_shards_back list must match numBusShardsBack. '), gacc.Attribute('numBusShardsAlert', gacc.Integer(), doc='The number of bus shards used by the Silver Tail Messaging System in the alert message bus. '), gacc.Attribute('subscriber_shards_alert', gacc.String(), doc='The number of items in the subscriber_shards_alert list must match numBusShardsAlert. ')), _(
        install_root='/var/opt/silvertail'
        , localhostname='lab6'
        , domain_name='silvertailsystems.com'
        , logs_path='/var/opt/silvertail/data/logs'
        , snapshot_path='/var/opt/silvertail/data/snapshot'
        , reports_path='/var/opt/silvertail/data/reports'
        , certs_cert='/var/opt/silvertail/certs/silvertail.crt'
        , certs_key='/var/opt/silvertail/certs/silvertail.key'
        , silverplex_host='lab6'
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
        ))
    , version=_(
        number='5.0.0.0-1249-g237d1de'
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
                , version=_(
                    number='5.0.0.0-1249-g237d1de'
                    )
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
        , _(
            name='multi-tenant-base'
            , overrides=_(
                multitenancy=_(
                    enabled=True
                    )
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
                    transactionAttributes=_(
                        userId='baseuser'
                        )
                    )
                , reportbuilder=_()
                , silversleuth=_(
                    transactionAttributes=_(
                        userId='baseuser'
                        )
                    )
                , clientanalyzer=_()
                )
            )
        , _(
            name='multi-tenant-std'
            , overrides=_(
                audit=_()
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
                , schema=_(
                    attribute=[
                        _(
                            _SUBTYPE='atomic.ordinary'
                            , id='baseuser'
                            , type='ARGS'
                            , name='username'
                            )
                        , _(
                            _SUBTYPE='atomic.ordinary'
                            , id='tenant'
                            , required=True
                            , type='REQUEST'
                            , name='tenant'
                            )
                        , _(
                            _SUBTYPE='concat'
                            , id='user'
                            , main='tenant'
                            , suffix='baseuser'
                            , suffixRequired=True
                            )
                        ]
                    , key=[
                        _(
                            name='user-ip'
                            , id='user-ip'
                            , val=[
                                _(
                                    id='tenant'
                                    )
                                ]
                            )
                        ]
                    , privilege=_()
                    )
                )
            )
        , _(
            name='multi-tenant-global'
            , base='multi-tenant-std'
            , overrides=_(
                multitenancy=_(
                    tenancyGlobal=True
                    )
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
                )
            )
        , _(
            name='multi-tenant-tenant'
            , base='multi-tenant-std'
            )
        , _(
            name='stms-alert'
            , overrides=_(
                _SYMBOLS=(gacc.Symbols(gacc.Attribute('stms_port', gacc.Integer())), _(
                    stms_port=26000
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
                , mitigator=_(
                    stmsAlertsOut=_(
                        numBusShards=gacc.Expr('numBusShardsAlert')
                        )
                    )
                , profileUpdater=_(
                    transactionAttributes=_()
                    )
                , silversleuth=_(
                    transactionAttributes=_()
                    )
                , clientanalyzer=_()
                , silverplex=_(
                    httpServerPort='12357'
                    )
                , stms=_(
                    numBusShards=gacc.Expr('numBusShardsAlert')
                    )
                , subscribers=_(
                    numBusShards=gacc.Expr('numBusShardsAlert')
                    , subscriber=[
                        _(
                            name=gacc.Expr('localhostname')
                            , shards=gacc.Expr('subscriber_shards_alert')
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
                        name='Cassandra'
                        , shard=gacc.Expr('ROOT.service.host.nickname')
                        )
                    , name='Cassandra'
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
                        name='MqBridge'
                        , shard='0'
                        )
                    , name='MqBridge'
                    , overlay='stms-back'
                    , httpServerPort='12360'
                    )
                , _(
                    program=_(
                        name='EdsServer'
                        , shard='0'
                        )
                    , name='EdsServer'
                    , httpServerPort='12361'
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
                    name='master'
                    , serviceClasses='SilverCat, VarzFetcher, VarzGrapher, VarzCache'
                    , childGroups='common'
                    )
                , _(
                    name='all-in-one'
                    , serviceClasses='SilverCat, VarzFetcher, VarzGrapher, VarzCache, SilverTap, PlexFront, SilverSurfer, PlexBack, Organizer, UIServer, AnnoDb, R2B2, ProfileUpdater, Indexer, SiteProxy, Mitigator, PlexAlert, IncidentServer, ActionServer, TaskScheduler, EdsServer, CProfileUpdater, Cassandra'
                    , childGroups='common'
                    )
                , _(
                    name='all-no-varz'
                    , serviceClasses='SilverCat, SilverTap, PlexFront, SilverSurfer, PlexBack, Organizer, UIServer, AnnoDb, R2B2, ProfileUpdater, Indexer, SiteProxy, Mitigator, PlexAlert, IncidentServer, ActionServer, EdsServer, CProfileUpdater, Cassandra'
                    , childGroups='common'
                    )
                , _(
                    name='tap'
                    , serviceClasses='SilverTap'
                    , childGroups='common'
                    )
                , _(
                    name='organizer'
                    , serviceClasses='Organizer'
                    , childGroups='common'
                    )
                , _(
                    name='corganizer'
                    , serviceClasses='COrganizer'
                    , childGroups='common'
                    )
                , _(
                    name='cassandra'
                    , serviceClasses='Cassandra'
                    , childGroups='common'
                    )
                , _(
                    name='mqbridge'
                    , serviceClasses='MqBridge'
                    , childGroups='common'
                    )
                , _(
                    name='ui'
                    , serviceClasses='UIServer, AnnoDb, SiteProxy'
                    , childGroups='common'
                    )
                , _(
                    name='rules'
                    , serviceClasses='R2B2, ProfileUpdater, Indexer, Mitigator'
                    , childGroups='common'
                    )
                , _(
                    name='ccp'
                    , serviceClasses='SilverCat, VarzFetcher, VarzGrapher, VarzCache, Distributor, PlexFront, SilverSurfer, AlertServer'
                    , childGroups='common'
                    )
                , _(
                    name='cprofileupdater'
                    , serviceClasses='CProfileUpdater'
                    , childGroups='common'
                    )
                , _(
                    name='surfer-pulisher-node'
                    , serviceClasses='SilverCat, VarzFetcher, VarzGrapher, VarzCache, PlexFront, SilverSurfer, PlexBack, Organizer, UIServer, AnnoDb, R2B2, ProfileUpdater, Indexer, SiteProxy, Mitigator, PlexAlert, IncidentServer, ActionServer, TaskScheduler, EdsServer'
                    , childGroups='common'
                    )
                ]
            , machineClass=[
                _(
                    name='master'
                    , serviceGroup='master'
                    )
                , _(
                    name='all-in-one'
                    , serviceGroup='all-in-one'
                    )
                , _(
                    name='all-no-varz'
                    , serviceGroup='all-no-varz'
                    )
                , _(
                    name='tap'
                    , serviceGroup='tap'
                    )
                , _(
                    name='organizer'
                    , serviceGroup='organizer'
                    )
                , _(
                    name='corganizer'
                    , serviceGroup='corganizer'
                    )
                , _(
                    name='cassandra'
                    , serviceGroup='cassandra'
                    )
                , _(
                    name='mqbridge'
                    , serviceGroup='mqbridge'
                    )
                , _(
                    name='ui'
                    , serviceGroup='ui'
                    )
                , _(
                    name='rules'
                    , serviceGroup='rules'
                    )
                , _(
                    name='ccp'
                    , serviceGroup='ccp'
                    )
                , _(
                    name='cprofileupdater'
                    , serviceGroup='cprofileupdater'
                    )
                , _(
                    name='surfer-pulisher-node'
                    , serviceGroup='surfer-pulisher-node'
                    )
                ]
            )
        , _(
            name='multi-tenancy'
            , serviceClass=[
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
                        , shard='global'
                        )
                    , name='Organizer-Global'
                    , overlay='stms-back'
                    )
                , _(
                    program=_(
                        name='Organizer'
                        , shard='tenant'
                        )
                    , name='Organizer-Tenant'
                    , overlay='stms-back'
                    )
                , _(
                    program=_(
                        name='SilverSleuth'
                        , shard='global'
                        )
                    , name='SilverSleuth-Global'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='SilverSleuth'
                        , shard='tenant'
                        )
                    , name='SilverSleuth-Tenant'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='R2B2'
                        , shard='global'
                        )
                    , name='R2B2-Global'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='R2B2'
                        , shard='tenant'
                        )
                    , name='R2B2-Tenant'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='Indexer'
                        , shard='global'
                        )
                    , name='Indexer-Global'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='Indexer'
                        , shard='tenant'
                        )
                    , name='Indexer-Tenant'
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
                        , shard='global'
                        )
                    , name='Mitigator-Global'
                    , overlay='stms-back'
                    )
                , _(
                    program=_(
                        name='Mitigator'
                        , shard='tenant'
                        )
                    , name='Mitigator-Tenant'
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
                        name='ProfileUpdater'
                        , shard='global'
                        )
                    , name='ProfileUpdater-Global'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='ProfileUpdater'
                        , shard='tenant'
                        )
                    , name='ProfileUpdater-Tenant'
                    , hasVarz=False
                    )
                , _(
                    program=_(
                        name='VarzCache'
                        , shard='0'
                        )
                    , name='VarzCache'
                    , hasVarz=False
                    )
                ]
            , serviceGroup=[
                _(
                    name='common'
                    , serviceClasses='Scout, ScoutProxy, SysStats'
                    )
                , _(
                    name='multi-tenancy-global'
                    , serviceClasses='SilverCat, VarzFetcher, VarzGrapher, VarzCache, Organizer-Global, UIServer, AnnoDb, R2B2-Global, ProfileUpdater-Global, Indexer-Global, SiteProxy, Mitigator-Global, CProfileUpdater, Cassandra'
                    , childGroups='common'
                    , overlay='multi-tenant-global'
                    )
                , _(
                    name='multi-tenancy-tenant'
                    , serviceClasses='SilverTap, PlexFront, SilverSurfer, PlexBack, Organizer-Tenant, R2B2-Tenant, ProfileUpdater-Tenant, Indexer-Tenant, Mitigator-Tenant'
                    , childGroups='common'
                    , overlay='multi-tenant-tenant'
                    )
                ]
            , machineClass=[
                _(
                    name='multi-tenancy-global'
                    , serviceGroup='multi-tenancy-global'
                    )
                , _(
                    name='multi-tenancy-tenant'
                    , serviceGroup='multi-tenancy-tenant'
                    )
                ]
            )
        ]
    , site=_(
        host=[
            _(
                name=gacc.Expr('localhostname')
                , machineClass='surfer-pulisher-node'
                )
            , _(
                name='lab5'
                , machineClass='cprofileupdater'
                )
            , _(
                name='lab9'
                , machineClass='cassandra'
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
        , endpoint=[
            _(
                program=_(
                    name='SysStats'
                    , shard='lab9'
                    )
                , host='lab9'
                , authType='basic'
                , url='https://lab9:4448/srv/sysstats/lab9/varz'
                , nickname='SysStats-lab9'
                )
            , _(
                program=_(
                    name='SysStats'
                    , shard='lab5'
                    )
                , host='lab5'
                , authType='basic'
                , url='https://lab5:4448/srv/sysstats/lab5/varz'
                , nickname='SysStats-lab5'
                )
            , _(
                program=_(
                    name='CProfileUpdater'
                    , shard='lab5'
                    )
                , host='lab5'
                , authType='basic'
                , url='https://lab5:4448/srv/cprofileupdater/lab5/varz'
                , nickname='CProfileUpdater-lab5'
                )
            , _(
                program=_(
                    name='SysStats'
                    , shard='lab6'
                    )
                , host='lab6'
                , authType='basic'
                , url='https://lab6:4448/srv/sysstats/lab6/varz'
                , nickname='SysStats-lab6'
                )
            , _(
                program=_(
                    name='VarzFetcher'
                    , shard='0'
                    )
                , host='lab6'
                , authType='basic'
                , url='https://lab6:4448/srv/varzfetcher/0/varz'
                , nickname='VarzFetcher-0'
                )
            , _(
                program=_(
                    name='VarzGrapher'
                    , shard='0'
                    )
                , host='lab6'
                , authType='basic'
                , url='https://lab6:4448/srv/varzgrapher/0/varz'
                , nickname='VarzGrapher-0'
                )
            , _(
                program=_(
                    name='SilverPlex'
                    , shard='front'
                    )
                , host='lab6'
                , authType='basic'
                , url='https://lab6:4448/srv/silverplex/front/varz'
                , nickname='SilverPlex-front'
                )
            , _(
                program=_(
                    name='SilverSurfer'
                    , shard='0'
                    )
                , host='lab6'
                , authType='basic'
                , url='https://lab6:4448/srv/silversurfer/0/varz'
                , nickname='SilverSurfer-0'
                )
            , _(
                program=_(
                    name='SilverPlex'
                    , shard='back'
                    )
                , host='lab6'
                , authType='basic'
                , url='https://lab6:4448/srv/silverplex/back/varz'
                , nickname='SilverPlex-back'
                )
            , _(
                program=_(
                    name='Organizer'
                    , shard='lab6'
                    )
                , host='lab6'
                , authType='basic'
                , url='https://lab6:4448/srv/organizer/lab6/varz'
                , nickname='Organizer-lab6'
                )
            , _(
                program=_(
                    name='UIServer'
                    , shard='0'
                    )
                , host='lab6'
                , authType='basic'
                , url='https://lab6:4448/srv/uiserver/0/varz'
                , nickname='UIServer-0'
                )
            , _(
                program=_(
                    name='Mitigator'
                    , shard='0'
                    )
                , host='lab6'
                , authType='basic'
                , url='https://lab6:4448/srv/mitigator/0/varz'
                , nickname='Mitigator-0'
                )
            , _(
                program=_(
                    name='SilverPlex'
                    , shard='alert'
                    )
                , host='lab6'
                , authType='basic'
                , url='https://lab6:4448/srv/silverplex/alert/varz'
                , nickname='SilverPlex-alert'
                )
            , _(
                program=_(
                    name='IncidentServer'
                    , shard='0'
                    )
                , host='lab6'
                , authType='basic'
                , url='https://lab6:4448/srv/incidentserver/0/varz'
                , nickname='IncidentServer-0'
                )
            , _(
                program=_(
                    name='TaskScheduler'
                    , shard='0'
                    )
                , host='lab6'
                , authType='basic'
                , url='https://lab6:4448/srv/taskscheduler/0/varz'
                , nickname='TaskScheduler-0'
                )
            , _(
                program=_(
                    name='EdsServer'
                    , shard='0'
                    )
                , host='lab6'
                , authType='basic'
                , url='https://lab6:4448/srv/edsserver/0/varz'
                , nickname='EdsServer-0'
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
    , admin=_(
        unprivilegedUser='silvertail'
        , suffix='.log.gz'
        , ipGeoDB=gacc.Expr("install_root + '/lib/GeoLiteCity.dat'")
        , logsPerTopicBits=4
        , ignorePriority=True
        , alertSpoolDirectory='/var/opt/silvertail/data/alerts'
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
        , mitigatorURL='https://lab6:4448/srv/mitigator/0'
        , makeCertPath=gacc.Expr("install_root + '/bin/makecert.sh'")
        , incidentServer=_(
            proxyURL='https://lab6:4448/srv/incidentserver/0'
            )
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
    , sysstats=_(
        httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
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
        , incidentEmail=_(
            UIServerHostName='lab6'
            )
        )
    , cOrganizer=_(
        httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
        , shardingPool=_()
        , cOrganizerPool=_()
        )
    , cProfileUpdater=_(
        httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
        , txnsPerScanner=100000
        , shardingPool=_()
        , cProfileUpdaterPool=_(
            numThreads=16
            )
        )
    , mqBridge=_(
        httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
        , mqBridgePool=_()
        )
    , organizer=_(
        httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
        , tasks=_(
            completed=gacc.Expr('tasks_organizer_out')
            )
        )
    , indexer=_(
        tasks=_(
            pending=gacc.Expr('tasks_organizer_out')
            , inProcess=gacc.Expr("tasks_indexer + '/in_process'")
            , failed=gacc.Expr("tasks_indexer + '/failed'")
            , completed=gacc.Expr('tasks_indexer_out')
            )
        )
    , metaindexer=_(
        tasks=_(
            pending='disabled'
            , inProcess=gacc.Expr("tasks_metaindexer + '/in_process'")
            , failed=gacc.Expr("tasks_metaindexer + '/failed'")
            , completed=gacc.Expr('tasks_metaindexer_out')
            )
        )
    , database=_(
        dbhost='lab6'
        , dbport=7078
        , dbname='silvertail'
        , dbuser='silvertail'
        , dbpasswd='silvertail'
        )
    , cassandraClient=_(
        host='lab9'
        , keyspace='silvertail_1398464563'
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
        nThreads=1
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
    , clientanalyzer=_()
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
                , id='user'
                , type='USER'
                , name='id'
                , percentDecode=True
                , maxlen=64
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='page'
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
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='qst1'
                , type='COOKIE'
                , name='_qSt1'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='janndam'
                , type='COOKIE'
                , name='JannDam'
                )
            , _(
                _SUBTYPE='atomic.ordinary'
                , id='nmref'
                , type='COOKIE'
                , name='nmref'
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
                , val=[
                    _(
                        id='status'
                        )
                    ]
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
                , salt='Y6TJQ571V1'
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
        tlsTrusted=_(
            x509=[
                _(
                    cert=gacc.Expr('certs_cert')
                    )
                ]
            )
        )
    , logger=_(
        priority='ERR'
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
    , edsServer=_(
        httpServerPort=gacc.Expr('ROOT.service.serviceClass.httpServerPort')
        , edsPath=gacc.Expr("install_root + '/data/edsserver'")
        )
    )
