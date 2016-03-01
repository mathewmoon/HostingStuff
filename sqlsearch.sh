#!/bin/bash

db=${1}
string=\'${2}\'
cols=()
#seperator="=$string OR"


for table in $(echo $(mysql -D $db -e 'show tables;')|sed "s/Tables_in_$db\ \ //g")
do
        col=$( echo $(mysql -D $db -e "SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_NAME='$table';")|sed 's/COLUMN_NAME//g'| sed -e 's/^[ \t]*//g'|sed "s/\ /\=$string\ OR\ /g")
        echo $(mysql -D $db -e "SELECT * FROM $table WHERE $col")|grep $string
done















-bash-4.1# egrep 'Feb  8 1(8|9):' /var/log/secure
Feb  8 18:01:13 host sshd[14068]: Accepted password for root from 62.38.155.142 port 1679 ssh2
Feb  8 18:01:13 host sshd[14068]: pam_unix(sshd:session): session opened for user root by (uid=0)
Feb  8 18:01:13 host sshd[14068]: subsystem request for sftp
Feb  8 18:03:49 host Cp-Wrap[15584]: Pushing "502 SORTEDRESELLERSUSERS root#012" to '/usr/local/cpanel/bin/reselleradmin' for UID: 502
Feb  8 18:03:49 host Cp-Wrap[15584]: CP-Wrapper terminated without error
Feb  8 18:03:50 host Cp-Wrap[15599]: Pushing "502 UPDATEPRIVS" to '/usr/local/cpanel/bin/cpmysqladmin' for UID: 502
Feb  8 18:03:51 host Cp-Wrap[15599]: CP-Wrapper terminated without error
Feb  8 18:03:51 host Cp-Wrap[15609]: Pushing "502 DBCACHE 1#012" to '/usr/local/cpanel/bin/cpmysqladmin' for UID: 502
Feb  8 18:03:51 host Cp-Wrap[15609]: CP-Wrapper terminated without error
Feb  8 18:03:51 host Cp-Wrap[15612]: Pushing "502 RESELLERSUSERS root#012" to '/usr/local/cpanel/bin/reselleradmin' for UID: 502
Feb  8 18:03:51 host Cp-Wrap[15612]: CP-Wrapper terminated without error
Feb  8 18:03:51 host Cp-Wrap[15614]: Pushing "502 SORTEDRESELLERSUSERS root#012" to '/usr/local/cpanel/bin/reselleradmin' for UID: 502
Feb  8 18:03:51 host Cp-Wrap[15614]: CP-Wrapper terminated without error
Feb  8 18:03:59 host Cp-Wrap[15673]: Pushing "502 UPDATEDBOWNER" to '/usr/local/cpanel/bin/cpmysqladmin' for UID: 502
Feb  8 18:03:59 host Cp-Wrap[15673]: CP-Wrapper terminated without error
Feb  8 18:08:53 host Cp-Wrap[17422]: Pushing "502 UPDATEDBOWNER" to '/usr/local/cpanel/bin/cpmysqladmin' for UID: 502
Feb  8 18:08:53 host Cp-Wrap[17422]: CP-Wrapper terminated without error
Feb  8 18:09:28 host Cp-Wrap[17454]: Pushing "502 UPDATEPRIVS" to '/usr/local/cpanel/bin/cpmysqladmin' for UID: 502
Feb  8 18:09:28 host Cp-Wrap[17454]: CP-Wrapper terminated without error
Feb  8 18:09:28 host Cp-Wrap[17457]: Pushing "502 DBCACHE 1#012" to '/usr/local/cpanel/bin/cpmysqladmin' for UID: 502
Feb  8 18:09:29 host Cp-Wrap[17457]: CP-Wrapper terminated without error
Feb  8 18:09:34 host Cp-Wrap[17507]: Pushing "502" to '/usr/local/cpanel/bin/securityadmin' for UID: 502
Feb  8 18:09:54 host passwd: pam_unix(passwd:chauthtok): password changed for angelsto
Feb  8 18:09:55 host Cp-Wrap[17539]: Pushing "502 REFRESH 0 0#012" to '/usr/local/cpanel/bin/ftpadmin' for UID: 502
Feb  8 18:09:56 host Cp-Wrap[17539]: CP-Wrapper terminated without error
Feb  8 18:09:56 host Cp-Wrap[17544]: Pushing "502 UPDATEDBOWNER#012" to '/usr/local/cpanel/bin/cpmysqladmin' for UID: 502
Feb  8 18:09:57 host Cp-Wrap[17544]: CP-Wrapper terminated without error
Feb  8 18:09:57 host Cp-Wrap[17547]: Pushing "502" to '/usr/local/cpanel/bin/securityadmin' for UID: 502
Feb  8 18:13:41 host Cp-Wrap[19633]: Pushing "502 UPDATEPRIVS" to '/usr/local/cpanel/bin/cpmysqladmin' for UID: 502
Feb  8 18:13:41 host Cp-Wrap[19633]: CP-Wrapper terminated without error
Feb  8 18:13:41 host Cp-Wrap[19636]: Pushing "502 DBCACHE 1#012" to '/usr/local/cpanel/bin/cpmysqladmin' for UID: 502
Feb  8 18:13:41 host Cp-Wrap[19636]: CP-Wrapper terminated without error
Feb  8 18:13:55 host Cp-Wrap[19698]: Pushing "502" to '/usr/local/cpanel/bin/securityadmin' for UID: 502
Feb  8 18:14:12 host passwd: pam_unix(passwd:chauthtok): password changed for angelsto
Feb  8 18:14:13 host Cp-Wrap[19732]: Pushing "502 REFRESH 0 0#012" to '/usr/local/cpanel/bin/ftpadmin' for UID: 502
Feb  8 18:14:14 host Cp-Wrap[19732]: CP-Wrapper terminated without error
Feb  8 18:14:14 host Cp-Wrap[19737]: Pushing "502 UPDATEDBOWNER#012" to '/usr/local/cpanel/bin/cpmysqladmin' for UID: 502
Feb  8 18:14:14 host Cp-Wrap[19737]: CP-Wrapper terminated without error
Feb  8 18:14:14 host Cp-Wrap[19742]: Pushing "502" to '/usr/local/cpanel/bin/securityadmin' for UID: 502
Feb  8 19:00:49 host Cp-Wrap[32694]: Pushing "502 UPDATEDBOWNER" to '/usr/local/cpanel/bin/cpmysqladmin' for UID: 502
Feb  8 19:00:50 host Cp-Wrap[32694]: CP-Wrapper terminated without error
Feb  8 19:07:20 host sshd[14068]: pam_unix(sshd:session): session closed for user root
-bash-4.1# 







