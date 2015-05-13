adupdate
========

This package provides a set of scripts that, upon receiving notification from 
NetworkManager, update the Active Directory Domain Controller.  It performs
secure updates with the credentials obtained when the machine was joined to
the domain using Samba.


Configuration
=============

First the machine must be joined to the network.  This requires configuring
Samba.  Assuming your Active Directory domain is called corp.example.com.

Then edit the /etc/samba/smb.conf file and make the following changes using 
your own names:

```
workgroup = corp
security = ads
realm = corp.example.com
```

To join the domain you will need credentials with the ability to create machine
accounts. Type the following Samba command:

```
net ads join -U user-name
```

Enter your password when prompted.

Now that the machine is a member of the domain the Kerberos keytab file must be
created:

```
adauth --config
```

The final step is configuring the update scripts.  In most cases the defaults
are sufficient.  If not, there are some settings that can be changed in 
/etc/sysconfig/adupdate.

PUBLIC_IFACE
------------

This is the network interface to which the addresses to be registered are 
assigned.  It defaults to eth0 but needs to be set if a different 
interface should be used such as br0 in the case of a bridge.

DC_SERVER
---------

Normally nsupdate retrieves the proper server from the domain's SOA record. 
But some versions don't handle it properly.  This causes the updates to be 
sent to the wrong server and rejected.  To fix this you can set 
DC_SERVER=lookup and the script will check the SOA itself.  If the updates 
should be sent to some other server then you can put its name here.

HOST
----

Usually the registered Host name is the same as the machine name and is 
retrieved using hostname -s.  If that is not the case then it can be 
overridden here.

DOMAIN
------

In most cases the Active Directory Domain and the machine's domain name 
are the same and can be retrieved using hostname -d.  If not, specify 
the domain here.

ALIASES
-------

Additional aliases can be created using CNAME records by listing them here 
separated by commas.
