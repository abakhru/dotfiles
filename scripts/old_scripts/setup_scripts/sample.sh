. common.sh

usage() {
clear # Clear the screen.

echo "Choose one of the option mentioned below to create the desired deployment & configuration:"
echo "-----------------------------------------------------------------------------------------"
echo
echo "0. Usage of the required funtions"
echo "1. Enable SSL"
echo "2. Enable TLS"
echo "3. Enable Register"
echo "4. Create Server2Server Deployment Scenario"
echo "5. Create Four-Peer Servers for Server-Pool Deployment Scenario"
echo "6. Enable Redirect Server"
echo
echo "Enter your Configuration option:"

read config_option

case "$config_option" in
  "0")  echo "Usage of the funtions used for this script is as follows:
========================================================
For creating instances: create_instance <instance_name> <no.of.instnaces>

For performing start/stop/refresh #operations on a particular server-instance: 
operation <instance_name> <instance_number> start/stop/refresh

For configure a particular server instance to specific deployment scenario:
configure <instance_name> <instance_no> "enable/disabe" <config_property>
" ;;

  "1")
        create_instance ssl_server 1
        configure ssl_server 1 enable ssl
        configure ssl_server 1 enable register
        #operation ssl_server 1 start
	##sleep 5
        #operation ssl_server 1 stop
	;;
  "2")
        create_instance tls_server 1
        configure tls_server 1 enable tls
        #operation tls_server 1 start
	#sleep 5
        #operation tls_server 1 stop
	;;

  "3")
        create_instance register_server 1
        configure register_server 1 enable register
        #operation register_server 1 start
	#sleep 5
        #operation register_server 1 stop
	;;
  "4")
        create_instance server2server 2
        configure server2server 1 enable s2s
        configure server2server 2 enable s2s
        configure server2server 1 enable tls
        configure server2server 2 enable tls
        configure server2server 1 enable register
        configure server2server 2 enable register
        #operation server2server 1 start
	#sleep 5
        #operation server2server 1 stop
        #operation server2server 2 start
	#sleep 5
        #operation server2server 2 stop
	;;
  "5")
	create_instance peer 4
	configure peer 1 enable pool
	configure peer 2 enable pool
	configure peer 3 enable pool
	configure peer 4 enable pool
	#operation peer 3 pool
	#sleep 5
	#operation peer 3 stop
	#clean peer
	;;
  "6")
	create_instance redirect 1
	configure redirect 1 enable redirect
	#operation redirect 1 start
	#sleep 5
	#operation redirect 1 stop
	;;
*)
  echo
  echo "Invalid option, Choose again";;
esac
}

