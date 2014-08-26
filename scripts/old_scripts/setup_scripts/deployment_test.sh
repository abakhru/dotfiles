. common.sh
current_dir=`pwd`

#null_port

test_ssl()
{
	clean
	create_instance sslserver 1
	configure sslserver 1 disable ssl
	configure sslserver 1 enable register
	operation sslserver 1 start
	sleep 10
	#s_port=`grep server_port port_numbers|cut -f2 -d=`
	#mux_port=`grep mux port_numbers|cut -f2 -d=`
	#cd /space/trunk/junit/com/sun/im/service
	#cp configuration.properties.template configuration.properties
	#sed -e "s/5269/$s_port/g" configuration.properties > abc.txt
	#sed -e "s/5222/$mux_port/g" abc.txt > configuration.properties
	#gmake ssl
	#cd $current_dir
	#operation ssl_server 1 stop

}

test_tls()
{
	clean
	create_instance tlsserver 1
	configure tlsserver 1 enable tls
	configure tlsserver 1 enable register
	operation tlsserver 1 start
	sleep 10
	#s_port=`grep server_port port_numbers|cut -f2 -d=`
	#mux_port=`grep mux port_numbers|cut -f2 -d=`
	#cd /space/trunk/junit/com/sun/im/service
	#cp configuration.properties.template configuration.properties
	#sed -e "s/5269/$s_port/g" configuration.properties > abc.txt
	#sed -e "s/5222/$mux_port/g" abc.txt > configuration.properties
	#gmake search
	#cd $current_dir
	#operation tls_server 1 stop

}

test_proxy()
{

	create_instance proxy_server 1
	configure proxy_server 1 enable register
	operation proxy_server 1 start
	sleep 10
	s_port=`grep server_port port_numbers|cut -f2 -d=`
	mux_port=`grep mux port_numbers|cut -f2 -d=`
	cd /space/trunk/junit/com/sun/im/service
	cp configuration.properties.template configuration.properties
	sed -e "s/5269/$s_port/g" configuration.properties > abc.txt
	sed -e "s/5222/$mux_port/g" abc.txt > configuration.properties
	gmake proxy
	cd $current_dir
	operation proxy_server 1 stop

}

test_httpbind()
{
	clean
	create_instance httpbind 1
	configure httpbind 1 enable register
	operation httpbind 1 start
	sleep 10
	#s_port=`grep server_port port_numbers|cut -f2 -d=`
	#mux_port=`grep mux port_numbers|cut -f2 -d=`
	#cd /space/trunk/junit/com/sun/im/service
	#cp configuration.properties.template configuration.properties
	#sed -e "s/5269/$s_port/g" configuration.properties > abc.txt
	#sed -e "s/5222/$mux_port/g" abc.txt > configuration.properties
	#cp $default_dir/config/httpbind.conf.template $default_dir/config/httpbind.conf
	#sed -e "s/5222/$mux_port/g" $default_dir/config/httpbind.conf > abc.txt
	#mv abc.txt $default_dir/config/httpbind.conf
	#gmake httptunnel
	#cd $current_dir
	#operation httpbind_server 1 stop

}

test_register()
{
	clean
	create_instance registerserver 1
        configure registerserver 1 enable register
        operation registerserver 1 start
        sleep 5
}

test_s2s()
{
	clean
	create_instance s2sserver 2
	configure s2sserver 1 disable s2s
	configure s2sserver 1 enable register
	configure s2sserver 2 enable s2s
	configure s2sserver 2 enable register
        change_domain s2sserver 2 $default_domain_name $secondary_domain_name	
        operation s2sserver 1 start
	operation s2sserver 2 start
	#sleep 10
	#cd /space/trunk/junit/com/sun/im/service
	#gmake search
	#cd $current_dir
	#operation s2sserver 1 stop
	#operation s2sserver 2 stop
	#cd $current_dir

}

test_virtual_domain()
{
	clean
        create_instance virtualdomain 1
        configure virtualdomain 1 enable register
        configure virtualdomain 1 enable identity
        configure virtualdomain 1 enable virtualdomain
        configure virtualdomain 1 enable identity
        operation virtualdomain 1 refresh
        sleep 5
}

test_identity()
{
	clean
        create_instance identity 1
        configure identity 1 enable identity
        operation identity 1 refresh
        sleep 5
}

test_redirect()
{
	clean
        create_instance redirect 1
        configure redirect 1 enable redirect
        operation redirect 1 start
        sleep 5
}

test_redirect_pool()
{
	clean
	create_instance redirect 1
	configure redirect 1 enable redirect
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
	#cd /space/trunk/junit/com/sun/im/service
	#gmake 121chat
	#cd $current_dir
	#for i in peer*
	#do
	#	operation peer_server $i stop
	#done
}


