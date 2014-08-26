dir=`pwd`
class_path=$dir/imnet.jar
echo $class_path
#java -cp $class_path org.netbeans.lib.collab.tools.Generate contractfiles/gen.txt
#java -cp $class_path org.netbeans.lib.collab.tools.Populate contractfiles/populate.txt
#java -cp $class_path org.netbeans.lib.collab.tools.Generate contractfiles/bigconf.txt
#java -Xdebug -Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=y -cp $class_path org.netbeans.lib.collab.tools.Generate contractfiles/conf-big.txt
#java -cp $class_path org.netbeans.lib.collab.tools.Generate contractfiles/contract-pres-update
java -cp $class_path org.netbeans.lib.collab.tools.Generate contractfiles/chat-contract
# java -Dorg.netbeans.lib.collab.CollaborationSessionFactory=org.netbeans.lib.collab.xmpp.httpbind.HTTPBindSessionProvider -cp $class_path org.netbeans.lib.collab.tools.Generate contractfiles/chat-contract
