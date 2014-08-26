The OpenSSL-based OCSP server is started with the following command:
    
    openssl ocsp -index index.txt -CA cacert.pem -port 8880 \
                 -rkey ocspkey.pem -rsigner ocspcert.pem \
                 -resp_no_certs -nmin 60 -text

The Command consists of the parameters

 -index  index.txt is a copy of the OpenSSL index file containing the list of
         all issued certificates. The certificate status in indext.txt
         is designated either by V for valid or R for revoked. If
         a new certificate is added or if a certificate is revoked
         using the openssl ca command, the OCSP server must be restarted
         in order for the changes in index.txt to take effect.

 -CA     the CA certificate

 -port   the HTTP port the OCSP server is listening on.
 
-rkey    the private key used to sign the OCSP response. The use of the
         sensitive CA private key is not recommended since this could
         jeopardize the security of your production PKI if the OCSP
         server is hacked. It is much better to generate a special
         RSA private key just for OCSP signing use instead.

-rsigner the certificate of the OCSP server containing a public key which
         matches the private key defined by -rkey and which can be used by
         the client to check the trustworthiness of the signed OCSP response.

-resp_no_certs  With this option the OCSP signer certificate defined by
                -rsigner is not included in the OCSP response.

-nmin    the validity interval of an OCSP response given in minutes.
         2*crlcheckinterval before the expiration of the OCSP responses,
         a new query will by pro-actively started by the Pluto fetching thread.

         If nmin is missing or set to zero then the default validity interval
         compiled into Pluto will be 2 minutes, leading to a quasi one-time
         use of the OCSP status response which will not be periodically 
         refreshed by the fetching thread. In conjunction with the parameter
        setting .strictcrlpolicy=yes. a real-time certificate status query
        can be implemented in this way.

-text   This option activates a verbose logging output, showing the contents
        of both the received OCSP request and sent OCSP response.

----------------------------------
7.1 Generating a CA certificate
    ---------------------------

The OpenSSL statement

     openssl req -x509 -days 1460 -newkey rsa:2048 \
                 -keyout caKey.pem -out caCert.pem

creates a 2048 bit RSA private key caKey.pem and a self-signed CA certificate
caCert.pem with a validity of 4 years (1460 days).

     openssl x509 -in cert.pem -noout -text

lists the properties of  a X.509 certificate cert.pem. It allows you to verify
whether the configuration defaults in openssl.cnf have been inserted correctly.

If you prefer the CA certificate to be in binary DER format then the following
command achieves this transformation:

     openssl x509 -in caCert.pem -outform DER -out caCert.der

The directory /etc/ipsec.d/cacerts contains all required CA certificates either
in binary DER or in base64 PEM format. Irrespective of the file suffix, Pluto
"automagically" determines the correct format.


7.2 Generating a host or user certificate
    -------------------------------------

The OpenSSL statement

     openssl req -newkey rsa:1024 -keyout hostKey.pem \
                 -out hostReq.pem

generates a 1024 bit RSA private key hostKey.pem and a certificate request
hostReq.pem which has to be signed by the CA.

If you want to add a subjectAltName field to the host certificate you must edit
the OpenSSL configuration file openssl.cnf and add the following line in the
[ usr_cert ] section:

     subjectAltName=DNS:soggy.strongsec.com

if you want to identify the host by its Fully Qualified Domain Name (FQDN ), or

     subjectAltName=IP:160.85.22.3

if you want the ID to be of type IPV4_ADDR. Of course you could include both
ID types with

     subjectAltName=DNS:soggy.strongsec.com,IP:160.85.22.3

but the use of an IP address for the identification of a host should be
discouraged anyway.

For user certificates the appropriate ID type is USER_FQDN which can be
specified as

     subjectAltName=email:ewa@strongsec.com

or if the user's e-mail address is part of the subject's distinguished name

     subjectAltName=email:copy

Now the certificate request can be signed by the CA with the command

     openssl ca -in hostReq.pem -days 730 -out hostCert.pem -notext

If you omit the -days option then the default_days value (365 days) specified
in openssl.cnf is used. The -notext option avoids that a human readable
listing of the certificate is prepended to the base64 encoded certificate
body.

If you want to use the dynamic CRL fetching feature described in section 4.7
then you must include one or several crlDistributionPoints in your end
certificates. This can be done in the [ usr_cert ] section of the openssl.cnf
configuration file:

    crlDistributionPoints= @crl_dp

    [ crl_dp ]

    URI.1="http://www.strongsec.com/ca/cert.crl"
    URI.2="ldap://ldap.strongsec.com/o=strongSec GmbH, c=CH
      ?certificateRevocationList?base?(objectClass=certificationAuthority)"

If you have only a single http distribution point then the short form

    crlDistributionPoints="URI:http://www.strongsec.com/ca/cert.crl"

also works. Due to a known bug in OpenSSL this notation fails with ldap URIs.

Usually a Windows-based VPN client needs its private key, its host or
user certificate, and the CA certificate. The most convenient way to load
this information is to put everything into a  PKCS#12 file:

     openssl pkcs12 -export -inkey hostKey.pem \
                    -in hostCert.pem -name "soggy" \
                    -certfile caCert.pem -caname "Root CA" \
                    -out hostCert.p12


7.3 Generating a CRL
    ----------------

An empty CRL that is signed by the CA can be generated with the command

     openssl ca -gencrl -crldays 15 -out crl.pem

If you omit the -crldays option then the default_crl_days value (30 days)
specified in openssl.cnf is used.

If you prefer the CRL to be in binary DER format then this conversion
can be achieved with

     openssl crl -in crl.pem -outform DER -out cert.crl

The directory /etc/ipsec.d/crls contains all CRLs either in binary DER
or in base64 PEM format. Irrespective of the file suffix, Pluto
"automagically" determines the correct format.


7.4 Revoking a certificate
    ----------------------

A specific host certificate stored in the file host.pem is revoked with the
command

     openssl ca -revoke host.pem

Next the CRL file must be updated

     openssl ca -gencrl -crldays 60 -out crl.pem

The content of the CRL file can be listed with the command

     openssl crl -in crl.pem -noout -text

in the case of a base64 CRL, or alternatively for a CRL in DER format

     openssl crl -inform DER -in cert.crl -noout -text

Convert crl.pem to crl.DER format
	
     openssl crl -outform der -in crl.pem -out crl.der

To verify a cert revoke status

     cat ./newcerts/cacert.pem crl.pem > revoke.pem
     openssl verify -CAfile revoke.com -crl_check ./newcerts/algy-cert.pem

=============================================================================
EXAMPLES

Create an OCSP request and write it to a file:

 openssl ocsp -issuer issuer.pem -cert c1.pem -cert c2.pem -reqout req.der

Send a query to an OCSP responder with URL http://ocsp.myhost.com/ save the response to a file and print it out in text form

 openssl ocsp -issuer issuer.pem -cert c1.pem -cert c2.pem \
     -url http://ocsp.myhost.com/ -resp_text -respout resp.der

Read in an OCSP response and print out text form:

 openssl ocsp -respin resp.der -text

OCSP server on port 8888 using a standard ca configuration, and a separate responder certificate. All requests and responses are printed to a file.

 openssl ocsp -index demoCA/index.txt -port 8888 -rsigner rcert.pem -CA demoCA/cacert.pem
        -text -out log.txt

As above but exit after processing one request:

 openssl ocsp -index demoCA/index.txt -port 8888 -rsigner rcert.pem -CA demoCA/cacert.pem
     -nrequest 1

Query status information using internally generated request:

 openssl ocsp -index demoCA/index.txt -rsigner rcert.pem -CA demoCA/cacert.pem
     -issuer demoCA/cacert.pem -serial 1

Query status information using request read from a file, write response to a second file.

 openssl ocsp -index demoCA/index.txt -rsigner rcert.pem -CA demoCA/cacert.pem
     -reqin req.der -respout resp.der

