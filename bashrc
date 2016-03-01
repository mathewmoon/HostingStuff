# .bashrc
# Specifically for using in hosting environments such as cPanel and Plesk
#


#if being used on a remote server we remove ourselves as soon as the file is loaded into memory and remove our line from /etc/profile
if [ -f /tmp/.bashrc_temp ]; then
	rm -f /tmp/.bashrc_temp
	sed -i '/REMOVE-ME/d' /etc/profile
fi 

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

#Export some stuff
[ -d /usr/local/cpanel ] && export HOME=/root #For cPanel servers so we get root access to mysql
[ -d /usr/local/psa ] && export MYPWD="$(cat /etc/psa/.psa.shadow)" #Get root password for Plesk servers
[ -d /usr/local/directadmin ] && export MYPWD="$(tail -n1 /usr/local/directadmin/conf/mysql.conf|cut -d= -f2)"
GREP_OPTIONS='--color=auto'
LS_OPTIONS='--color'


#Define paths to some things we will need often
dedicated_key=~/.ssh/dedicated_id_dsa
my_key=~/.ssh/id_rsa

########################################################### 
#                       Aliases                           #
###########################################################    

function whereami(){
	[ -d /vz/private ] && echo 'node' || echo 'container'
}

function isnode(){
	[ -d /vz/private ] && return 0 || return 1
}

function ve(){
	curl --silent -F pwd='*****' -F file=mathew_bashrc xxx.xxx.xxx.xxx >/vz/root/${1}/tmp/.bashrc_temp
	echo '[ -f /tmp/.bashrc_temp ] && source /tmp/.bashrc_temp #REMOVE-ME' >>/vz/root/${1}/etc/profile
	vzctl enter $1
}

function syncrc(){
	rsync .bashrc root@paste.foobar:/home/support/html/scripts/mathew_bashrc
	ssh root@paste.foobar "chown -R support:support /home/support/html/scripts/"
	rsync -e "ssh -p22" .bashrc foo@bar:/root/myscripts/.bashrc
	rsync -e "ssh -p22" .noderc foo@bar:/root/myscripts/.noderc
}

function dedi(){
	if [[ -z $2 ]]; then
	        port=2200
	else
	        port=$2
	fi
	scp -q -i $dedicated_key -P${port} ~/.bashrc support@${1}:/tmp/.bashrc_temp
	ssh -o LogLevel=quiet -t -i $dedicated_key -p${port} support@${1} "sudo bash --rcfile /tmp/.bashrc_temp"
}

function node(){
	if [[ ! -z $2 ]]
	then
		scp -q ~/.bashrc root@$1.foobar:/vz/root/$2/tmp/.bashrc_temp
		ssh -o LogLevel=quiet root@$1.foobar <<EOF
			if ! grep -q bashrc_temp /vz/root/$2/etc/profile
			then
				echo '[ -f /tmp/.bashrc_temp ] && source /tmp/.bashrc_temp #REMOVE-ME'>>/vz/root/$2/etc/profile
			fi
EOF
		ssh -o LogLevel=quiet root@$1.foobar -tt "vzctl enter $2"
	else
		scp -q ~/.noderc root@$1.foobar:/tmp/.noderc
		ssh -o LogLevel=quiet -t root@$1.foobar "bash --rcfile /tmp/.noderc"
	fi
}

function go(){
	ssh -o LogLevel=quiet -p2200 root@$1
}

function install(){
	
	[ -z $1 ] && (echo 'What are we installing?' && return)

	[ $1 == 'kpaste' ] && (curl --silent -F pwd='*******' -F file=kpaste xxx.xxx.xxx.xxx >/bin/kpaste; chmod +x /bin/kpaste)

	[ $1 == 'htop' ] && htop

	[ $1 == 'modsec' ] && curl xxx.xxx.xxx.xxx/packages/modsec_installer.sh|bash

	[ $1 == 'sar' ] && yum -y install sysstat

	[ $1 == 'sysstat' ] && yum -y install sysstat

	if [ $1 == 'csf' ]
	then
		cd /usr/local/src
		wget http://configserver.com/free/csf.tgz
		tar zxf csf.tgz
		cd csf
		./install.sh
		sed -i 's/TESTING = "1"/TESTING = "0"/' /etc/csf/csf.conf
		csf -r
		echo -e "\nCSF has been installed and started\n"
	fi

	if [ $1 == 'nginx' ]
	then
		cd /usr/local/src
		wget http://nginxcp.com/latest/nginxadmin.tar
		tar xf nginxadmin.tar
		cd publicnginx
		./nginxinstaller install
	fi

	if [ $1 == suphp ]
	then
		/usr/local/cpanel/bin/rebuild_phpconf 5 none suphp 1
		curl --silent -F pwd='******' -F file=suphp_fixperms xxx.xxx.xxx.xxx|bash		
	fi
}

function whm(){
	function randomString() {
		index=0
		str=""
		for i in {a..z}; do arr[index]=$i; index=`expr ${index} + 1`; done
		for i in {A..Z}; do arr[index]=$i; index=`expr ${index} + 1`; done
		for i in {0..9}; do arr[index]=$i; index=`expr ${index} + 1`; done
		for i in {1..8}; do str="$str${arr[$RANDOM%$index]}"; done
		echo $str
	}

	passwd=$(randomString)
	passwdHash=$(openssl passwd $passwd)

	if [[ $1 =~ ^(ssd|vz)[0-9]*-(wa|tx|ca|nj)$ ]]
	then
		type=vps
		address=$(ssh -o LogLevel=quiet root@$1.foobar vzctl exec $2 "useradd -M -s /bin/bash -p $passwdHash support\;hostname -i\;hostname")
		ssh -o LogLevel=quiet root@$1.foobar vzctl exec $2 "echo 'support:all'>>/vz/root/$2/var/cpanel/resellers;cat /vz/root/$2/var/cpanel/resellers"
		ip=$(echo $address|awk '{print $1}')
		hostname=$(echo $address|awk '{print $2}')

	elif [[ $1 =~ ^[0-9].*$ ]]
	then
		type=dedi	
		address=$1
		ip=$address
		if [[ $2 == '' ]]
		then
			port=2200
		else
			port=$2
		fi
		ssh -o LogLevel=quiet -tt -i $dedicated_key support@$address -p $port "sudo useradd -M -s /bin/bash -p$passwdHash support"
		ssh -o LogLevel=quiet -tt -i $dedicated_key support@$address -p $port "sudo sh -c \"echo 'support:all'>>/var/cpanel/resellers\""

	else
		echo Bad Address
		return 1
	fi	

	echo -e "\npassword is $passwd user support\n"
	echo "https://${ip}:2087/login/?user=support&pass=${passwd}"

	echo "You have 20 minutes. Press [enter] to remove login now."
	read -t 1200 timeout
	if [[ $type == 'vps' ]]
	then
		ssh -o LogLevel=quiet root@$1.foobar vzctl exec $2 "userdel support\;sed -i '/^support.*$/d' /var/cpanel/resellers"
	else
		ssh -o LogLevel=quiet -i $dedicated_key support@$address -p $port -tt "sudo userdel support"
		ssh -o LogLevel=quiet -i $dedicated_key support@$address -p $port -tt "sudo sh -c \"/bin/sed -i '/^support.*$/d' /var/cpanel/resellers\""
	fi

	echo "Removed account";
}

function healthreport(){
	log='/root/support/health_report'`date +%m%d%Y-%M`
	mkdir -p /root/support
	curl --silent -F pwd='********' -F file=health_report xxx.xxx.xxx.xxx|bash|tee $log
	curl --silent -F file=@$log paste.foobar
}

function getmaillogins(){
	if [ -d /usr/local/psa ]; then
		echo 'Plesk.....Ughhhh!'
		return
	fi
	[ -d /usr/local/cpanel ] && log=/var/log/exim_mainlog
	[ -d /usr/local/directadmin ] && log=/var/log/exim/mainlog 
	grep -E 'A=(dovecot|courier)' $log|sed 's/^.* A=//g'|awk '{print $1}'|sort|uniq -c|sort -n
}

function getmailscripts(){
	if [ -d /usr/local/psa ]; then
		echo 'Plesk.....Ughhhh!'
		return
	fi
	[ -d /usr/local/cpanel ] && log=/var/log/exim_mainlog
	[ -d /usr/local/directadmin ] && log=/var/log/exim/mainlog 
	grep 'cwd=/home' $log|sed 's/^.*=\|[0-9]* args.*$//g'|sort|uniq -c|sort -n
}

function banhammer(){
        iptables -F DROPSPAMMERS 2>/dev/null
        iptables -X DROPSPAMMERS 2>/dev/null
        iptables -N DROPSPAMMERS 2>/dev/null
        echo -e "###############################################################################\nBanhammer `date`\n###############################################################################\n"
        echo -e "Flushing iptables.\n"
        echo -e "\nLooking for bot addresses in domlogs. This may take a while.\n"
	comm -12 <(wget -qO- http://listed.foobar/latest/stopforumspam.com/bannedips.csv|sort) <(find /usr/local/apache/domlogs /var/www/vhosts/*/statistics/logs/access_log /var/log/httpd/domains -type f 2>/dev/null|egrep -v 'bytes_log|ftpx|error\.log'|xargs awk '{print $1}'|egrep -v '\=|[a-zA-Z]|0-9]{4}'|sort|uniq)|xargs -I % sh -c ' iptables -A DROPSPAMMERS -j DROP -s %; echo "Dropped %";'|tee dropped
        wc -l dropped
        rm -f dropped
        echo -e "\nDone scanning.\n"
}

function nodetop(){
	ssh -t root@$1.foobar top
}

function stopexim(){
	killall -9 exim
	sed -i 's/exim:1/exim:0/g' /etc/chkserv.d/chkservd.conf
	sed -i 's/exim-26:1/exim-26:0/g' /etc/chkserv.d/chkservd.conf
	/scripts/restartsrv_chkservd
	if [ -z "$(pgrep exim)" ]; then
		echo -e "\nExim is stopped and won't be restarted by chkservd\n"
	fi
}

function restartexim(){
        sed -i 's/exim:0/exim:1/g' /etc/chkserv.d/chkservd.conf
        sed -i 's/exim-26:0/exim-26:1/g' /etc/chkserv.d/chkservd.conf
        /scripts/restartsrv_chkservd
	service exim start || echo -e "\nCould not start exim\n"
        [ ! -z $(pgrep exim) ] && echo -e "\nExim is started and back in chkservd\n"
}

function lockexim(){
	killall -9 exim
	chmod 000 `which exim`
	chattr +i `which exim`
	which exim 2>/dev/null
	ls -l `which exim` 2>/dev/null
	[[ $? != 0 ]] && echo -e "\n Exim is locked down!\n"
}

function unlockexim(){
	which exim
	chattr -i /usr/sbin/exim
	chmod 4755 /usr/sbin/exim
	which exim
	if [[ $? == 0 ]]
	then
		echo -e "\n Exim has been unlocked\n"
	else
		echo -e "\n Could not unlock Exim\n"
	fi
	ls -l /usr/sbin/exim
	service exim start
}

function clearexim(){
	killall -9 exim
	mv /var/spool/exim /exim.bad
	nohup rm -rf /exim.bad 1>&2 &>/dev/null 1>&2 &>/dev/null &
	echo -e "\nremoving exim queue\n"
}

function getcmsversions(){
	for dir in $(grep DocumentRoot /usr/local/apache/conf/httpd.conf|awk '{print $2}')
	do 
		echo "$(egrep -s '\$RELEASE|\$wp_version =' $dir/libraries/joomla/version.php $dir/includes/version.php $dir/wp-includes/version.php)"|egrep 'RELEASE|version'
	done
}	

function messg(){
	for user in $(find /dev/pts|egrep '[0-9]$')
	do
		echo -e "\n${1}\n">>"$user"
	done
}

function getipstats(){
	if [ $1 == '--help' ]; then
	echo -e "This tool gets the number of hits by each IP address appearing in a given domain's domlog.\nUsage: getipstats <domain> <time>. The <time> is optional. If included specify a time in the same\nformat as the timestamp in the logs appear.\n	ie: getipstats somedomain.com 12/Dec/2013:04\nThis will return the number of hits per IP address only from 4AM to 4:59 AM on Dec 12, 2013.\nOtherwise it will parse the entire domlog from start to finish."
		return
	fi

        if [[ -f /usr/local/apache/domlogs/${1} ]]; then
                LOG_PATH="/usr/local/apache/domlogs/${1}"
        elif [[ -f /var/www/vhosts/${1}/statistics/logs/access_log ]]; then
                LOG_PATH="/var/www/vhosts/${1}/statistics/access_log"
        else
                echo "Could not find the log. Specify the domain name."
                return
        fi

        if [ ! -z $2 ]; then
                grep $2 $LOG_PATH|awk '{print $1}'|sort|uniq -c|sort -nr|head -50
        else
                awk '{print $1}' $LOG_PATH|sort|uniq -c|sort -nr|head -50
        fi
}

function gethourlytraffic(){
        if [ -z $1 ]; then
                echo "Specify a domain or -all for all domains"
                return
        elif [ $1 == '-all' ]; then
                echo "checking all domains"
                for log in $(find /usr/local/apache/domlogs /var/www/vhosts/*/statistics/logs/access_log /var/log/httpd/domains -maxdepth 1 -type f 2>/dev/null|egrep -v 'bytes_log|ftpx|error\.log|ftp_log|offsetftp')
                do
                        domain=${log##*/}
                        echo "--- $domain ---"
                        for hour in {00..23}
                        do
				hits="$(egrep -c "$(date +'%d/%h/%Y'):${hour}:[0-9]+:[0-9]+" $log)"
                                [[ $hits != 0 ]] && echo "$hour:00:00 $hits"
                        done
                done
        else
                [ -f /usr/local/apache/domlogs/${1} ] && log="/usr/local/apache/domlogs/${1}"
                [ -f /var/www/vhosts/${1}/statistics/access_log ] && log="/var/www/vhosts/${1}/statistics/access_log"
                domain=${log##*/}
                echo "--- $domain ---"
                for hour in {01..23}
                do
                        echo "$hour:00:00 $(egrep -c "$(date +'%d/%h/%Y'):${hour}:[0-9]+:[0-9]+" $log)"
                done
        fi
}

function htop(){
	if [ ! -x /bin/htop ]; then
		wget xxx.xxx.xxx.xxx/packages/htop -P /bin >/dev/null 2>&1 || echo "Cannot download htop."
		curl xxx.xxx.xxx.xxx/packages/htoprc > /root/.htoprc
		chmod +x /bin/htop 2>/dev/null
	fi
	/bin/htop
}

#function iotop(){
#	if ! which iotop; then
#		wget xxx.xxx.xxx.xxx/packages/iotop.rpm
#		rpm -i iotop.rpm
#		rm -f iotop.rpm
#	fi
#	$(which iotop)
#}

function findbigdirs(){
        for d in $(ls -1a |grep -v '\.\.')
        do
                echo "$d: $(find "$d" -type f | wc -l)"
        done | sort -nk2
}

function getdbengine(){
	echo "SELECT ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA='${1}'"|mysql
}

function mytail(){
	tail $1 /var/lib/mysql/`hostname`.err|less
}

function upcpcheck(){
	ls -lt --time-style=+%M/%d/%Y /var/cpanel/updatelogs/update.*.log|head -1|awk '{print $6,$7}'
	grep '^=> Log closed' $(ls -t /var/cpanel/updatelogs/update.*.log|head -1)|tail -1
}

function checkforinnodb(){
	mysql --skip-column-names -B -e "SELECT concat_ws(' = ',concat_ws('.',table_schema,table_name),engine) FROM information_schema.TABLES WHERE TABLE_SCHEMA='$1'"|grep -i innodb
}

function fixeximstats(){
        if [ ! -d /usr/local/cpanel/ ]; then
		echo "Not a cpanel server"
		return
	fi

        if [ ! -f /usr/local/cpanel/etc/eximstats_db.sql ]; then
		echo "No dump file located in /usr/local/cpanel/etc/eximstats_db, downloading now"
		curl http:/xxx.xxx.xxx.xxx/packages/eximstats_db.sql >/usr/local/cpanel/etc/eximstats_db.sql
	fi

        if [ ! -f /usr/local/cpanel/etc/eximstats_db.sql ]; then
		echo "Could not download new db. Exiting"
		return
	fi

        echo "Clearing eximstats."
        mysqladmin -f drop eximstats
	echo "Eximstats dropped. Creating new db."
	mysqladmin create eximstats
	mysql eximstats < /usr/local/cpanel/etc/eximstats_db.sql && echo "Eximstats db created" || echo "Could not create eximstats db."
}

function supportdir(){
	[ ! -d /root/support ] && mkdir /root/support
	cd /root/support
}

function auditaccounts(){
	supportdir	
	curl -k --silent -F pwd='********' -F file=audit.sh https:/xxx.xxx.xxx.xxx >audit.sh
	chmod +x audit.sh
	./audit.sh
}

function bouncencron(){
        mailpath=$(echo $1|sed 's#/$##')
        mailpath=${mailpath%/*}
	curmail="$mailpath/cur"
	newmail="$mailpath/new"
	nohup ionice -c 2 -n 2 bash -c "egrep -Rli '<>|cron' $newmail|xargs rm -f"  1>&2 &>/dev/null 1>&2 &>/dev/null &
	if [ "$2" = 'all' ]; then
		nohup ionice -c 2 -n 2 bash -c "egrep -Rli '<>|cron' $curmail|xargs rm -f"  1>&2 &>/dev/null 1>&2 &>/dev/null &
	fi
}

function statmail(){
        mailpath=$(echo $1|sed 's#/$##')
        mailpath=${mailpath%/*}
	curmail="$mailpath/cur"
	stat -c %y $curmail
}

function deletenewmail(){
        mailpath=$(echo $1|sed 's#/$##')
        mailpath=${mailpath%/*}
	curmail="$mailpath/cur"
	newmail="$mailpath/new"
	nohup ionice -c 2 -n 2 bash -c "find $newmail -type f -delete" 1>&2 &>/dev/null 1>&2 &>/dev/null &
}

alias auditaccounts=auditaccounts
alias banhammer=banhammer
alias bouncencron=bouncencron $1
alias checkforinnodb=checkforinnodb $1
alias cpu="grep -c proc /proc/cpuinfo"
alias dedi='dedi'
alias deflate="netstat -ntu | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -n"
alias deletenewmail=deletenewmail $1
alias fixeximstats=fixeximstats
alias findbigdirs=findbigdirs
alias findmaildirs="for dir in find /vz/root/*/home/*/mail/cur /vz/root/*/home/*/mail/*/cur -type d -name cur -mtime +360; do du -sm "$(echo $dir|sed 's/cur/new/')" 2>/dev/null; done|egrep '^[0-9]{3}'|sort -nr"
alias getcmsversions=getcmsversions
alias getdbengine=getdbengine $1
alias getdomlogstart="head -1 /usr/local/apache/domlogs/$1|awk '{print $4}'"
alias gethandler="/usr/local/cpanel/bin/rebuild_phpconf --current"
alias gethourlytraffic=gethourlytraffic $1
alias getip='curl -F getip=true paste.foobar'
alias getipstats=getipstats $1
alias getmailscripts=getmailscripts
alias getmaillogins=getmaillogins
alias getquotas="repquota -a 2>/dev/null|awk '{print \$6,\$1}'|egrep -v '#|Block|\*|User|used|\-'|sort -n"
alias go=go
alias healthreport=healthreport
alias htop=htop
alias install=install ${1}
alias kpaste=kpaste $1
alias ktools='ssh -o LogLevel=quiet root@10.0.2.113'
alias letmein=whm
alias lockexim=lockexim
alias messg=messg
alias mounttmp="echo 'tmpfs /tmp tmpfs nodev,nosuid 0 0' >>/etc/fstab;mount -a;mount|grep tmp"
alias mytail="mytail $1"
alias myvps='ssh root@mathewmoon.net -p2222'
alias nano='nano -c'
alias node='node'
alias nodetop=nodetop $1
alias stopexim=stopexim
alias restartexim=restartexim
alias stat='stat -c "%n %y"'
alias statmail=statmail $1
alias supportdir=supportdir
alias unlockexim=unlockexim
alias upcpcheck=upcpcheck
alias whm=whm
alias vpn='sudo openvpn ~/openvpn/kh/kh.conf >/dev/null 2>&1 &'
alias ve=ve $1

#Aliases that depend on certain things such as what panel we are running
[ -d /usr/local/psa ] && alias mysql="echo '$MYPWD';mysql -uadmin -p'$MYPWD'"
[ -d /usr/local/psa ] && alias mysqladmin="mysqladmin -uadmin -p'$MYPWD'"
[ -d /usr/local/psa ] && alias version='cat /etc/redhat-release;cat /usr/local/psa/version'
[ -d /usr/local/cpanel ] && alias version='cat /etc/redhat-release;cat /usr/local/cpanel/version'
[ -d /usr/local/directadmin ] && alias mysql="mysql -uda_admin -p'$MYPWD'"
[ -d /usr/local/directadmin ] && alias mysqladmin="mysqladmin -uda_admin -p'$MYPWD'"
[ -d /usr/local/directadmin ] && alias mysqlcheck="mysqlcheck -uda_admin -p'$MYPWD'"

#Modifications to existing commands
alias lt='ls -1tr --color=auto'
alias la='ls -1tra --color=auto'
alias ll='ls -1lhatr --color=auto'
alias lr='ls -1Rhatr --color=auto'



