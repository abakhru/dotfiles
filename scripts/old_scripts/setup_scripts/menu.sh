!/bin/bash
set -x
current_dir = `pwd`
cd /space/prithvi/setup_scripts/
. common.sh
ans="yes"
while [ $ans == "yes" ]
do
clear # Clear the screen.

echo "Choose one of the option mentioned below to create the desired deployment & configuration:"
echo "-----------------------------------------------------------------------------------------"
echo
echo "0.  Usage of the required funtions"
echo "1.  Enable SSL"
echo "2.  Enable TLS"
echo "3.  Enable Register"
echo "4.  Create Server2Server Deployment Scenario"
echo "5.  Enable Hosted Domain"
echo "6.  Enable SSO/Identity "
echo "7.  Enable Redirect Server"
echo "8.  Enable Redirect Server wiht Server-Pool Scenario"
echo "9.  Enable Httpbind Gateway"
echo "10. Clean the Instance"
echo "11. Exit"
echo
echo -e "Enter your Configuration option: \c" 

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
        echo "Choose the option for enable or disable SSL"
        echo 
	echo "If you are running this script first time your can't select second option"
	echo "because the SSL instance is not yet created"
	echo "--------------------------------------------------------------------------"
	echo
	echo "1: Enable the SSL"
	echo "2: Disable the SSL"
	echo
	echo -e "Enter the option : \c"
	read option
	case "$option" in
	"1")
		clean
		echo "Enable SSL will first create the SSL instanct and then it will Enable the SSL" 
		sleep 5
		create_instance sslserver 1
        	configure sslserver 1 enable ssl
        	configure sslserver 1 enable register
        	operation sslserver 1 start 
		sleep 10
		;;
	"2")
		configure sslserver 1 disable ssl
		operation sslserver 1 refresh
		sleep 5
		echo "SSL is disabled"
		sleep 10
		;;
	*)
		echo "Invalid option........Try Again."
	
	esac
    ;; 
   "2")
	echo "Choose the option for enable or disable TLS"
	echo 
        echo "If you are running this script first time your can't select second option"
        echo "because the TLS instance is not yet created"
        echo "--------------------------------------------------------------------------"
	echo
        echo "1: Enable the TLS"
        echo "2: Disable the TLS"
	echo
        echo -e "Enter the option : \c"
        read option
        case "$option" in
	"1")
		clean
		echo "Enable TLS will first create the TLS instance and then it will Enable the TLS"
		sleep 5
        	create_instance tlsserver 1
        	configure tlsserver 1 enable tls
		configure tlsserver 1 enable register
        	operation tlsserver 1 start
		sleep 5
		;;
	"2")
		configure tlsserver 1 disable tls
		operation tlsserver 1 refresh
		sleep 5
		echo "TLS is disabled"
		;;
	*)
		echo "Invalid Option.........Try Again."
	esac
   ;;
  "3")
	echo "Choose the option for enable or disable Register"
	echo
	echo "If you are Registering first time then you can't select second option"
	echo "because New user Registration instance is not yet created"
	echo "----------------------------------------------------------------------"
	echo
	echo "1: Enable Register"
	echo "2: Disable Register"
	echo
	echo -e "Enter the option : \c"
	read option
	case "$option" in 
	"1")
		clean
        	create_instance registerserver 1
 	        configure registerserver 1 enable register
	        operation registerserver 1 start
		sleep 5
		;;
	"2")
		configure registerserver 1 disable register
		operation registerserver 1 refresh
		sleep 5
		echo "New User Registration is disable"
		;;
	*)
		echo "Invalid option...........Try Again."
	esac
   ;;
  "4")
	echo "Choose the option for enable or disable Server to Server deployment"
        echo
        echo "If you are Creating Server to Server deployment first time then you can't select second option"
        echo "because Server to Server deployment is not yet done"
        echo "-----------------------------------------------------------------------------------------------"
	echo
        echo "1: Enable s2s" 
        echo "2: Disable s2s"
        echo
        echo -e "Enter the option : \c"
        read option
        case "$option" in
        "1")
                clean
		create_instance s2sserver 2
        	configure s2sserver 1 enable s2s
        	configure s2sserver 1 enable register
        	configure s2sserver 2 enable s2s
        	configure s2sserver 2 enable register
        	change_domain s2sserver 2 $default_domain_name $secondary_domain_name
        	operation s2sserver 1 start
        	operation s2sserver 2 start
		sleep 5
		echo "Server to Server deployment is created"
		;;
	"2")
		configure s2sserver 1 disable s2s
		configure s2sserver 2 disable s2s
		operation s2sserver 1 refresh
		operation s2sserver 2 refresh
		sleep 5
		echo "Server to Server deployment is disabled"
		;;
	*)
		echo "Invalid option..............Try Again."
	esac
    ;;
   "5")
	echo "Choose the option for enable or disable Virtual Domain"
        echo
        echo "If you are deploying Virtual Domain first time you can't select second option"
        echo "because Virtual Domain deployment is not yet created"
        echo "-----------------------------------------------------------------------------"
	echo
        echo "1: Enable Register"
        echo "2: Disable Register"
        echo
        echo -e "Enter the option : \c"
        read option
        case "$option" in
        "1")
                clean
		create_instance virtualdomain 1
		configure virtualdomain 1 enable register
		configure virtualdomain 1 enable identity
		configure virtualdomain 1 enable virtualdomain
		configure virtualdomain 1 enable identity
		operation virtualdomain 1 refresh
		sleep 5
		echo "Virtual Domain deployment is created"
		;;
	"2")
		configure virtualdomain 1 disable virtualdomain
		operation virtualdomain 1 refresh
		sleep 5
		echo "Virtual Domain deployment is disabled"
		;;
	*)
		echo "Invalid Option............Try Again."
	esac
    ;;
   "6")
	echo "Choose the option for enable or disable Identity"
	echo
	echo "If you are enabling Identity first time you should not select second option"
	echo "Because Identity is not yet deployed"
	echo "----------------------------------------------------------------------------"
	echo
	echo "1: Enable Identity"
	echo "2: Disable Identity"
	echo
	echo -e "Enter the Option : \c"
	read option
	case "$option" in
	"1")
		clean
		create_instance identity 1
		configure identity 1 enable identity
		operation identity 1 refresh
		sleep 5
		echo "Identity is deployed"
		;;
	"2")
		configure identity 1 disable identity
		operation identity 1 refresh
		sleep 5
		echo "Identity is disabled"
		;;
	*)
		echo "Invalid Option.......Try Again."
	esac
    ;;
   "7")
	echo "Choose the option for enable or disable Redirect Server"
        echo
        echo "If you are deploying redirect server first time then you can't select second option"
        echo "because redirect deployment is not yet created"
        echo "-----------------------------------------------------------------------------------"
	echo
        echo "1: Enable Register"
        echo "2: Disable Register"
        echo
        echo -e "Enter the option : \c"
        read option
        case "$option" in
        "1")
                clean
		create_instance redirect 1
		configure redirect 1 enable redirect
		operation redirect 1 start
		sleep 5
		echo "Redirect Server is created"
		;;
	"2")
		configure redirect 1 disable redirect
		operation redirect 1 refresh
		sleep 5
		echo "Redirect Server is disabled"
		;;
	*)
		echo "Invalid Option.........Try Again."
	esac
    ;;
   "8")
	echo "Choose the option for enable or disable Redirect Server with Server Pool"
        echo
        echo "If you are creating Server Pool first time you can't select second option"
        echo "because server pool deployment is not yet created"
        echo "-------------------------------------------------------------------------"
	echo
        echo "1: Enable Register"
        echo "2: Disable Register"
        echo
        echo -e "Enter the option : \c"
        read option
        case "$option" in
        "1")
                clean
		create_instance redirect 1
		configure redirect 1 enable redirect
		mux_port=`expr $mux_port + $i`
                server_port=`expr $server_port + $i`

		create_instance peer 4
		cd $dest_dir
		for i in 1 2 3 4
		do
			configure peer $i enable pool
			configure peer $i enable register
			operation peer $i start
			sleep 5
		done
		sleep 5
		echo "Server Pool with redirect server is created"
		;;
	"2")
		configure redirect 1 disable redirect
		for i in 1 2 3 4
		do
			configure peer $i disable pool
			operation peer $i refresh
			sleep 5
		done
		sleep 5
		echo "Server Pool with Redirect Server is disabled"
		;;
	*)
		echo "Invalid Option........Try Again."
	esac
    ;;
   "9")
	echo "Choose the option for enable or disable Httpbind"
        echo
        echo "If you are enabling Httpbind Gateway first time you can't select second option"
        echo "because Httpbind Gateway deployment is not yet created"
        echo "------------------------------------------------------------------------------"
        echo
        echo "1: Enable Httpbind"
        echo "2: Disable Httpbind"
        echo
        echo -e "Enter the option : \c"
        read option
        case "$option" in
        "1")
                clean
		create_instance httpbind 1
		configure httpbind 1 enable httpbind
		operation httpbind 1 start
		sleep 5
		echo "Httpbind deployment is created"
		;;
	"2")
		configure httpbind 1 disable httpbind
		operation httpbind 1 start
		sleep 5
		echo "Httpbind deployment is disabled"
		;;
	*)
		echo "Invalid Option..........Try Again."
	esac
    ;;
   "10")
	clean
	echo "Instance has been deleted"
	sleep 5
	;;
   "11")
	exit
    ;;
    *)
	echo "Invalid option, Choose again"
        echo 
	echo -e "Want to Continue.....[Yes/No] : \c"
	read ans

	if [ $ans == "yes" ] || [ $ans == "Yes" ] 
	then
		ans="yes"
		continue
	else
		exit
	fi 
	
esac
done
