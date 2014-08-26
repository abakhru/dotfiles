#!/bin/bash -x
	(
        sleep 1 
        echo "ehlo" 
        sleep 1 
        echo "AUTH PLAIN bmVvMzMAbmVvMzMAbmVvMzM=" 
        sleep 1 
        echo "mail from: neo33" 
        sleep 1 
        echo "rcpt to: neo42" 
        sleep 1 
        echo "data" 
        sleep 1 
        echo "subject:Test message" 
        sleep 1 
        echo "From:neo33"
        sleep 1 
        echo "To:neo42"
        sleep 1 
        echo " " 
        echo "Hello." 
        echo "This is a test message." 
        echo "Bye." 
        echo "." 
        sleep 1 
        echo "QUIT" ) | telnet dianthos.sfbay.sun.com 25
