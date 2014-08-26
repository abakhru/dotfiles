#!/bin/bash
#set -x
. setup.conf
. port_numbers
script_dir=`pwd`

mkdir -p $dest_dir/logs/

# Uncomment below line to redirect all the console message to common.log file
exec 2> $dest_dir/logs/common.log.`date '+20%y%m%d%H%M%S'`  

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#Funtion for creating the number of IM-Server required by the testcase
#Usage of this function is as follows:
#
# create_instance <instance_name> <number_of_such_instance>
#
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
create_instance()
{
	# Checking whether two argument are passed to the method
	if [ $# -ne 2 ] 
	then
		echo "
		Required number of argument is not passed to the function
		Usage of this function is as follows:
		
		 create_instance <instance_name> <number_of_such_instance>
		
		=========================================================="
		exit 0
	fi # if condition ends
	echo > $install_dir/redirect.hosts

	i=1
	while [ $i -le $2 ] 
	do
		server_name=$1$i
		new_mux_port=`expr $mux_port + $i`
		new_server_port=`expr $server_port + $i`
	
		#Creating new instance directory
		cp -R $default_dir $dest_dir/$server_name/
		cp -R $default_var_dir $dest_var_dir/$server_name/

		echo "mux_port=$new_mux_port" > $dest_dir/$server_name/$server_name.conf
		echo "server_port=$new_server_port" >> $dest_dir/$server_name/$server_name.conf
		echo "instance_name=$server_name" >> $dest_dir/$server_name/$server_name.conf

		#Cleaning all the files inside db & log directories
		rm -rf $dest_var_dir/$server_name/db/*
		rm -rf $dest_var_dir/$server_name/log/*
		cd $dest_dir/$server_name/config/
	
		echo "new_mux_port=$new_mux_port & new_server_port=$new_server_port for instance_name=$server_name"
		sed -e "s/5222/$new_mux_port/g" iim.conf > iim.conf.bk
		sed -e "s/5269/$new_server_port/g" iim.conf.bk > iim.conf
		sed '/instancedir/ s/iim/! iim/' iim.conf > iim.conf.bk
		sed '/instancevardir/ s/iim/! iim/' iim.conf.bk > iim.conf
		sed '/domainname/ s/iim/! iim/' iim.conf > iim.conf.bk

		mv iim.conf.bk iim.conf 
		echo "
iim.instancedir=$dest_dir/$server_name
iim.instancevardir=$dest_var_dir/$server_name
iim_server.domainname=\"$default_domain_name\" " >> iim.conf
		sed '/log4j.config/ s/iim/! iim/' iim.conf > iim.conf.bk
		echo "
iim.log4j.config=$dest_dir/$server_name/config/log4j.conf" >> iim.conf.bk
		mv iim.conf.bk iim.conf
		echo "`hostname`.$machine_domainname:$new_mux_port" >> $install_dir/config/redirect.hosts

		echo "

! Number of Last X messages to be delivered after joining a conference room.
! ================================================================
iim_server.conference.history.maxstanzas.default=3
iim_server.conference.history.maxstanzas=10
iim_server.conference.history.persist=true
	" >> iim.conf
		#sed "s/default/$server_name/" ../imadmin > ../imadmin.bk;mv ../imadmin.bk ../imadmin
		echo "$install_dir/sbin/imadmin -c $dest_dir/$server_name/config/iim.conf \$@" > ../imadmin
		chmod +x ../imadmin
		#Enabling the server debug logs
		sed 's/INFO/DEBUG/g' $dest_dir/$server_name/config/log4j.conf > $dest_dir/$server_name/config/log4j.conf.bk
		sed '/A3/ s/# //' $dest_dir/$server_name/config/log4j.conf.bk > $dest_dir/$server_name/config/log4j.conf
		sed '/jso.BasicStream=/ s/OFF/ON/
		' $dest_dir/$server_name/config/log4j.conf > $dest_dir/$server_name/config/log4j.conf.bk
		mv $dest_dir/$server_name/config/log4j.conf.bk $dest_dir/$server_name/config/log4j.conf
		echo "Creation of IM-$server_name instance complete"
		cd -
		i=`expr $i + 1`
	done #while loop ends

	cp $dest_dir/$server_name/$server_name.conf $script_dir/port_numbers
} #create_instnace() ends


#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Funtion to perform the start/stop/refresh operation on the given server instance
# Usage of this function is as follows:
#
# operation <instance_name> <instance_number> start/stop/refresh
#
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
operation()
{
	# Checknig whether two argument are passed to the method
	if [ $# -ne 3 ]
	then
      		echo "
		Required number of argument is not passed to the function
		Usage of this function is as follows:
		
		 operation <instance_name> <instance_number> start/stop/refresh
		
		==============================================================="
		exit 0
	fi
	server_name=$1$2

	case "$3" in
       		 "start" )
       		         echo "$server_name Server Starting"
       		         $dest_dir/$server_name/imadmin start ;;
       		 "stop" )
       		         echo "$server_name Server Stopping"
       		         $dest_dir/$server_name/imadmin stop ;;
       		 "refresh" )
       		         echo "$server_name Server Refreshing"
       		         $dest_dir/$server_name/imadmin refresh ;;
       		 "status" )
       		         echo "Showing $server_name Status"
       		         $dest_dir/$server_name/imadmin status ;;
	esac
} # operation() ends


#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#Funtion for Configuring the given instance number
#Usage of this function is as follows:
#
# configure <instance_name> <instance_number> enable/disable <property_name>
#
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
configure()
{
	# Checknig whether two argument are passed to the method
	if [ $# -ne 4 ]
	then
       		echo "
		Required number of argument is not passed to the function
		Usage of this function is as follows:
		
		configure <instance_name> <instance_number> enable/disable <property_name>
		
		==========================================================================="
		exit 0
	fi

	server_name=$1$2
	case "$4" in
       		 "register" )
       		         case "$3" in
       			         "enable" )
       			                  echo "
! New user registration is ENABLED
!=================================
iim.register.enable=true
iim_ldap.register.basedn=ou=people,o=$default_domain_name,dc=india,dc=sun,dc=com
iim_ldap.register.domain=$default_domain_name" >> $dest_dir/$server_name/config/iim.conf ;;
       			         "disable" )
sed '/register/d' $dest_dir/$server_name/config/iim.conf > $dest_dir/$server_name/config/iim.conf.bk
                mv $dest_dir/$server_name/config/iim.conf.bk $dest_dir/$server_name/config/iim.conf ;;
       		         esac ;; # register enable/disable case loop ends
 	      	 "ssl" )
       		         case "$3" in
       			         "enable" )
       			                 echo "

! Multiplexor SSL is Enabled
!===========================
iim_mux.usessl=on
iim_mux.secconfigdir=/net/nicp103/space/repository/orionscripts/certs
iim_mux.keydbprefix=https-nicp103.india.sun.com-nicp103-
iim_mux.certdbprefix=https-nicp103.india.sun.com-nicp103-
" >> $dest_dir/$server_name/config/iim.conf ;;
       			         "disable" )
       		               		  sed '/usessl/ s/on/off/
					 ' $dest_dir/$server_name/config/iim.conf > $dest_dir/$server_name/config/iim.conf.bk
					 mv $dest_dir/$server_name/config/iim.conf.bk \
					 $dest_dir/$server_name/config/iim.conf ;;
       			         * )
       			                 echo "To disble or enable paramter is not passed properly" ;;
       		         esac ;; # ssl enable/disable case loop ends

	       	 "tls" )
       		         case "$3" in
       			         "enable" )
       			                 echo "
!To Enable TLS for IM-Server
!===========================
iim_server.usessl=true
iim_server.sslkeystore=/net/nicp103/space/repository/orionscripts/certs/server_keystore.jks
iim_server.keystorepasswordfile=/net/nicp103/space/repository/orionscripts/certs/sslpassword.conf
" >> $dest_dir/$server_name/config/iim.conf ;;
       			         "disable" )
       		  	               	sed '/usessl/ s/true/false/
					 ' $dest_dir/$server_name/config/iim.conf > $dest_dir/$server_name/config/iim.conf.bk
					 mv $dest_dir/$server_name/config/iim.conf.bk \
					 $dest_dir/$server_name/config/iim.conf ;; 
       			         * )
       			                 echo "To disable or enable tls paramter is not passed properly" ;;
       		         esac ;; # tls enable/disable case loop ends

		"s2s" )
			case "$3" in
				"enable" )
					echo "
! Enabling Server2Server Communication Parameters
!===============================================
iim_server.serverid=$server_name.`hostname`.$machine_domainname
iim_server.password=$server_name" >> $dest_dir/$server_name/config/iim.conf
					cd $dest_dir
					for i in $1*
					do
						if [ $server_name == $i ]
						then
							continue
						else
	
							sed 's/=/ /' $i/$i.conf > $i/$i.conf.bk
							x=`grep -i server_port $i/$i.conf.bk|awk '{ print $2 }'`
							y=`grep -i instance_name $i/$i.conf.bk|awk '{ print $2 }'`
							rm $i/$i.conf.bk
							echo "Server Port is = $x"
							echo "Server instance name is = $y"
echo "
iim_server.coservers=coserver1
						
iim_server.coserver1.host=`hostname`.$machine_domainname:$x
iim_server.coserver1.serverid=$y.`hostname`.$machine_domainname
iim_server.coserver1.password=$y
iim_server.coserver1.domain=$default_domain_name
" >> $dest_dir/$server_name/config/iim.conf 
						fi # if condition ends
					done # for loop ends
					cd -;;
				"disable" )
		sed '/coserver/d' $dest_dir/$server_name/config/iim.conf  > $dest_dir/$server_name/config/iim.conf.bk 
		mv $dest_dir/$server_name/config/iim.conf.bk $dest_dir/$server_name/config/iim.conf 
						echo "S2S is disabled" ;;
			esac ;; # s2s enable/disable case loop ends

		"redirect" )
			case "$3" in
				"enable" ) 
					# Creating the redirect.db
					# ========================
					/$install_dir/sbin/rdadmin -c $dest_dir/$server_name/config/iim.conf generate
					mv $dest_var_dir/$server_name/db/redirect.new.db \
					$dest_var_dir/$server_name/db/redirect.db
					echo "
iim_server.redirect.provider=db,roundrobin
iim_server.redirect.db.users=$dest_var_dir/$server_name/db/redirect
iim_server.redirect.db.partitions=$install_dir/config/redirect.hosts
iim_server.redirect.db.partitionsize=10
iim_server.redirect.roundrobin.partitions=$install_dir/config/redirect.hosts
					" >> $dest_dir/$server_name/config/iim.conf ;;
			"disable" )
					sed '/redirect.provider/ s/iim/! iim/' $dest_dir/$server_name/config/iim.conf > $dest_dir/$server_name/config/iim.conf.bk
					#' iim.conf > $dest_dir/$server_name/config/iim.conf.bk
					mv $dest_dir/$server_name/config/iim.conf.bk $dest_dir/$server_name/config/iim.conf
	       	                        echo "Redirection is disabled" ;;
			esac ;; # enable/disable of redirect parameters ends

		"identity" )
			case "$3" in
				"enable" )
					#for enabling SSO
					sed -e '/useidentityadmin/ s/false/true/;
					/usesso/ s/0/1/;/policy.modules/ s/iim_ldap/identity/;/userprops.store/ s/file/ldap/
					' $dest_dir/$server_name/config/iim.conf > $dest_dir/$server_name/config/iim.conf.bk
					mv $dest_dir/$server_name/config/iim.conf.bk \
					$dest_dir/$server_name/config/iim.conf
					;;
				"disable" )
					#for disabling SSO
					sed '97a\
					iim_ldap.usergroupbinddn=netscape\
					' $dest_dir/$server_name/config/iim.conf > $dest_dir/$server_name/config/iim.conf.bk
					sed -e '/useidentityadmin/ s/true/false/;/usesso/ s/1/0/;
					/policy.modules/ s/identity/iim_ldap/;/userprops.store/ s/ldap/file/
					' $dest_dir/$server_name/config/iim.conf.bk > $dest_dir/$server_name/config/iim.conf
					;;
			esac ;; # enable/disable of identity/sso parameters ends

       	 "pool" )
       	         case "$3" in
       	                 "enable" )
				echo "
! Enabling Server2Server Communication Parameters
!================================================
iim_server.serverid=$server_name.`hostname`.$machine_domainname
iim_server.password=$server_name" >> $dest_dir/$server_name/config/iim.conf
instance_num=1
cd $dest_dir
       	                        for i in $1*
       	                        do
       	               		         if [ $server_name == $i ]
       	                       		 then
       	                               	        continue
       	                      		 else
       	                    			sed 's/=/ /' $i/$i.conf > $i/$i.conf.bk
       	                      			x=`grep -i server_port $i/$i.conf.bk|awk '{ print $2 }'`
       	                    			y=`grep -i instance_name $i/$i.conf.bk|awk '{ print $2 }'`
       	                 			rm $i/$i.conf.bk
			       	                echo "Server Port is = $x"
			       	                echo "Server instance name is = $y"
						b[$instance_num]=coserver$instance_num
       	    			                echo "
iim_server.coserver$instance_num.host=`hostname`.$machine_domainname:$x
iim_server.coserver$instance_num.serverid=$y.`hostname`.$machine_domainname
iim_server.coserver$instance_num.password=$y
iim_server.coserver$instance_num.domain=$default_domain_name
">> $dest_dir/$server_name/config/iim.conf
			                  	instance_num=`expr $instance_num + 1`
       	               			   fi # if loops ends
       	                        done # for loop ends
			        cd -
				#coserver_names=${b[0]},${b[1]},${b[2]},${b[3]}
				coserver_names=${b[1]},${b[2]},${b[3]}
				echo "
iim_server.coservers=$coserver_names" >> $dest_dir/$server_name/config/iim.conf ;;

       	                 "disable" )
       	                         sed '/coserver/d' $dest_dir/$server_name/config/iim.conf > $dest_dir/$server_name/config/iim.conf.bk
       	                         mv $dest_dir/$server_name/config/iim.conf.bk $dest_dir/$server_name/config/iim.conf
       	                         echo 'S2S is disabled' ;;
       	         esac ;; # enable/disable pool paramter case loop ends

            "virtualdomain")
	
                     case "$3" in
                         "enable" )
                                     echo "
! To enable search in  virtual domain
! ===================================
iim_server.discofilter.principal.any=true
iim_server.discofilter.conference.any=true
iim_server.discofilter.domains.any=true ">> $dest_dir/$server_name/config/iim.conf ;;

                         "disable" )
		                sed '/discofilter/d' $dest_dir/$server_name/config/iim.conf > $dest_dir/$server_name/config/iim.conf.bk
               			mv $dest_dir/$server_name/config/iim.conf.bk $dest_dir/$server_name/config/iim.conf
                   		echo "Virtualdomain is disabled" ;;   
                     esac ;; # VirtualDomain enable/disable case loop ends

		 "httpbind")
                     case "$3" in
                        "enable" )

				sed '/iim_agent.httpbind.enable = \"false\"/ d' $dest_dir/$server_name/config/iim.conf > $dest_dir/$server_name/config/iim.conf.bk
				sed '/httpbind.jid = \"\"/ d' $dest_dir/$server_name/config/iim.conf.bk > $dest_dir/$server_name/config/iim.conf
				sed '/httpbind.password = \"\"/ d' $dest_dir/$server_name/config/iim.conf > $dest_dir/$server_name/config/iim.conf.bk
				mv $dest_dir/$server_name/config/iim.conf.bk $dest_dir/$server_name/config/iim.conf
                                echo "
iim_agent.httpbind.enable = true
httpbind.jid = httpbind.`hostname`.$default_domain_name
httpbind.password = netscape ">> $dest_dir/$server_name/config/iim.conf

				sed '/default/ d' $dest_dir/$server_name/config/httpbind.conf > $dest_dir/$server_name/config/httpbind.conf.bk
				mv $dest_dir/$server_name/config/httpbind.conf.bk  $dest_dir/$server_name/config/httpbind.conf

				echo "
httpbind.config=default
default.domains=$default_domain_name
default.hosts=`hostname`.$default_domain_name:$new_mux_port
default.componentjid=httpbind.`hostname`.$default_domain_name
default.password=netscape
httpbind.log4j.config=$dest_dir/config/httpbind_log4j.conf ">>$dest_dir/$server_name/config/httpbind.conf

				sed 's/ERROR/DEBUG/' $dest_dir/$server_name/config/httpbind_log4j.conf > $dest_dir/$server_name/config/httpbind_log4j.conf.bk
				mv $dest_dir/$server_name/config/httpbind_log4j.conf.bk $dest_dir/$server_name/config/httpbind_log4j.conf ;;

                     "disable" )
				sed '/httpbind.enable/ s/true/false/' $dest_dir/$server_name/config/iim.conf > $dest_dir/$server_name/config/iim.conf.bk
				mv $dest_dir/$server_name/config/iim.conf.bk $dest_dir/$server_name/config/iim.conf ;;
			esac ;; #Httpbind enable/disable case loop ends

		esac # identity/s2s/register/ssl/tls/pool/redirect/virtualdomain case loop ends
} # configure() ends

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Function for Cleaning the given instances
# Usage of this function is as follows:
#
# clean <instance_name>
#
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
clean()
{
	# Checknig whether two argument are passed to the method
	#if [ $# -ne 1 ]
	#then
	#	echo 'Required number of argument is not passed to the function
	#	Usage of this function is as follows: clean instance_name
	#	========================================================='
	#	exit 0
	#fi 

#	cd $dest_dir

#	if [ -e $11 ]
#	then
#		for i in $1*
#		do
#			$i/imadmin stop
#		done # for loop ends
		
#		rm -rf $dest_dir/$1*
#		rm -rf $dest_var_dir/$1*
#                rm -rf $dest_dir/logs 
#	else
#		echo "No directory with such name as $1 exists"
#	fi 

	null_port	
	cd /space/prithvi/test/
	
	if [ $config_option -ne 10 ]
	then
		
		for i in  `\ls`
		do
			cd $i
			./imadmin stop
			cd ..
			if [ $i == "logs" ]
			then
				continue
			fi
			rm -rf $i
			rm -rf /var/opt/SUNWiim/$i
		done
	else
		for i in `\ls`	
		do
			cd $i
			./imadmin stop
			cd ..
			rm -rf $i
			rm -rf /var/opt/SUNWiim/$i
		done
	fi
	cd $current_dir

	cd -
	echo "All directories are deleted"
} #clean() ends


change_domain()
{
        # Checknig whether two argument are passed to the method
        if [ $# -ne 4 ]
        then
                echo "Required number of argument is not passed to the function
                Usage of this function is as follows:
               change_domain instant_name total_server $default_domain_name $ secondary_domain_name
                ===================================================================================="
                exit 0
        fi
                       cd $dest_dir/$11/config

                       sed '/iim_server.domainname="india.sun.com"/ d' iim.conf > iim.conf.bk
                       sed '/iim_server.coserver1.domain=india.sun.com/ d' iim.conf.bk > iim.conf
                       rm iim.conf.bk

echo "
iim_server.domainname=\"$default_domain_name\"
iim_server.coserver1.domain=$secondary_domain_name ">> $dest_dir/$11/config/iim.conf

               cd $dest_dir/$12/config

               sed '/iim_server.domainname="india.sun.com"/ d' iim.conf > iim.conf.bk
                sed '/iim_server.coserver1.domain=india.sun.com/ d' iim.conf.bk > iim.conf
               rm iim.conf.bk


echo "
iim_server.domainname=\"$secondary_domain_name\"
iim_server.coserver1.domain=$default_domain_name ">> $dest_dir/$12/config/iim.conf
}


null_port()
{
echo "mux_port=5222
server_port=5269"> port_numbers
}
