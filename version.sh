#!/bin/bash

###
#
# Get the version of panel and webapps on a server
#
###

if [ -d /usr/local/psa ]; then
        PANEL='Plesk'
        MYPWD="$(cat /etc/psa/.psa.shadow)"
fi

if [ -d /usr/local/directadmin ]; then
        PANEL='DirectAdmin'
        MYPWD="$(tail -n1 /usr/local/directadmin/conf/mysql.conf|cut -d= -f2)"
fi

if [ -d /usr/local/cpanel ]; then
        PANEL='cPanel'
        export HOME=/root
fi

function pleskDomains(){
        [ ! -d /usr/local/psa ] && return

        DOMAIN_LIST="$(mysql -uadmin -p$(cat /etc/psa/.psa.shadow) psa -Ns -e "select name from domains")"
        for domain in $DOMAIN_LIST
        do
                DOC_ROOTS="$DOC_ROOTS /var/www/vhosts/$domain/httpdocs/"
        done

        DOMAIN_LIST="$(mysql -uadmin -p$(cat /etc/psa/.psa.shadow) psa -Ns -e "select www_root from subdomains")"
        for subdomain in $DOMAIN_LIST
        do
                DOC_ROOTS="$DOC_ROOTS $subdomain"
        done

        PLESK_DOC_ROOTS="$DOC_ROOTS"
}

function cpanelDomains(){
        [ ! -d /usr/local/cpanel ] && return
        CPANEL_DOC_ROOTS="$(grep DocumentRoot /usr/local/apache/conf/httpd.conf|awk '{print $2}'|grep -v '/usr/local/apache/htdocs')"
}

function wordpressversions(){
        DOC_ROOTS="$PLESK_DOC_ROOTS $CPANEL_DOC_ROOTS"

        WORDPRESS_VERSION_LIST="$(echo "$(
                for dir in $DOC_ROOTS
                do
                        echo "$dir$(grep -s '\$wp_version =' ${dir}/wp-includes/version.php|egrep 'RELEASE|version'|sed -e 's/\$wp_version = /:/g' -e "s/;\|'//g")"|grep ':'
                done
        )"|sed 's#/httpdocs/##g')"

}

function joomlaversions(){
        DOC_ROOTS="$PLESK_DOC_ROOTS $CPANEL_DOC_ROOTS"

        JOOMLA_VERSION_LIST="$(
                for dir in $DOC_ROOTS
                do
                grep -sq Joomla $dir/index.php || continue
                version="$(echo "$(grep -s '\$RELEASE' $dir/libraries/joomla/version.php $dir/includes/version.php)"|grep 'RELEASE')"

                #if they deleted the version file then we have to do all kinds of silly shit to find the version
                        if [ -z $version ]; then
                     moo_version="$(echo "$(egrep -so 'version:"(1\.12|([0-9]\.){3})[0-9]' ${dir}/media/system/js/mootools-more.js)"|sed 's/version:"\|"$//g')"
                     case $moo_version in
                         '1.12') version='1.5'
                           ;;
                      '1.3.0.1') version='1.6'
                           ;;
                      '1.3.2.1') version='1.7'
                           ;;

                     esac

                     if [ $moo_version=='1.4.0.1' ]; then
                      if grep -sq '<version>2.5' $dir/language/en-GB/en-GB.xml; then
                              version='2.5.x'
                      else
                        version='3.x'
                      fi
                     fi
                fi
                echo "${dir}:${version}"
                done
        )"
}

function checkjoomla(){
        [ -z "$JOOMLA_VERSION_LIST" ] && return

        LATEST_VERSION="$(curl --silent http://update.joomla.org/core/list.xml|egrep -so 'version=\"[0-9].*'|sed 's/version=\|"//g'|sed 's/ .*//g'|tail -1)"

        echo -e "\n#\n#The latest version of Joomla is $LATEST_VERSION.\n#For all Joomla sites below version 2.5 the 2.5 tree is the suggested upgrade version. For any versions that were installed from the 2.x tree above 2.5, 3.x is recommended.\n#See http://www.joomla.org/download.html for more information.\n#"

        for joomla in $JOOMLA_VERSION_LIST
        do
                version="${joomla##*:}"
                dir="${joomla%:*}"

                if [ ! -z "$(echo "$version"|grep ^1.)" ]; then
                        upgrade='Upgrade to 2.5.x or 3.x.x'
                else
                        upgrade=''
                fi

                if [ ! -z "$(echo $version|grep x)" ]; then
                        upgrade="$upgrade ***"
                fi

                if [ -z "$(echo "$CHECK"|grep 'Upgrade')" ]; then
                        PASS='[Pass]'
                else
                        PASS='[FAIL]'
                fi

                echo "$dir $version $upgrade    $PASS"
        done
        echo -e '\n     *** Denotes that version was checked in a non-standard way due to the fact that your version file was missing. You may want to double check the version.'
}


function checkwordpress(){
        [ -z "$WORDPRESS_VERSION_LIST" ] && return
        LATEST_WP=$(curl --silent --head http://wordpress.org/latest |grep ^Content-Disposition|sed 's/.*wordpress-\|\.tar.*//g')

        echo -e "\n#\n#Latest WordPress version is $LATEST_WP. Note that WordPress only actively maintains the current latest stable version. Any previous version will not receive security patches and should be considered vulnerable.\n#"

        for site in $WORDPRESS_VERSION_LIST
        do
                SITE_PATH=${site%:*}
                VERSION=${site##*:}
                CHECK="$(echo "$(curl --silent http://api.wordpress.org/core/version-check/1.0/?version=$VERSION 2>/dev/null || (sleep 2; curl --silent http://api.wordpress.org/core/version-check/1.0/?version=$VERSION 2>/dev/null))"|sed 's/http.*//g')"

                if [ "$CHECK" == 'upgrade' ]; then
                        PASS='[FAIL]'
                else
                        PASS='[PASS]'
                fi

                echo "$SITE_PATH - $VERSION  $CHECK     $PASS"
        done
}

function apache(){
        echo -e "\n####################################################################\n               Apache and PHP\n###################################################################\n"

        echo -e "\nApache version:"
        httpd -v

#       echo -e "\nApache modules:"
#       httpd -M 2>/dev/null

        echo -e "\nPHP version:"
        php -v

#       echo -e "\nPHP Modules:"
#       php -m

        # Handler
        case $PANEL in
                cPanel) echo -e "\nPHP Handler Info:"
                        /usr/local/cpanel/bin/rebuild_phpconf --current
                        ;;

                 Plesk) echo -e "\nServer API (PHP handler):"
                        API="$(php -i|grep -w 'Server API'| sed 's|</b>|-|g' | sed 's|<[^>]*>||g'|sed 's/^.*API //')"
                        if [ ! -z "$(echo $API|grep -i cgi)" ]; then
                                echo "PHP is being run as CGI with suPHP or FastCGI"
                        fi
                        ;;

           DirectAdmin) echo -e "\nServer API (PHP handler):"
                        API="$(php -i|grep -w 'Server API'| sed 's|</b>|-|g' | sed 's|<[^>]*>||g'|sed 's/^.*API //')"
                        if [ ! -z "$(echo $API|grep -i cgi)" ]; then
                                echo "PHP is being run as CGI with suPHP or FastCGI"
                        fi
                        ;;
        esac
}

function firewall(){
        echo -e "\n###################################################################\n                        Firewall\n###################################################################\n"

        if which csf >/dev/null 2>&1; then

                FIREWALL='CSF   [PASSED]'

                CSF='Installed'

                if [ -f /etc/csf/csf.disable ]; then
                        CSF_DISABLE='CSF Firewall is installed, but disabled!   [FAIL]'
                else
                        CSF_DISABLE='CSF Firewall is not disabled.      [PASS]'
                fi

                if ! pgrep lfd >/dev/null; then
                        LFD_RUNNING='LFD is installed, but does not appear to be running!       [FAIL]'
                else
                        LFD_RUNNING="LFD running as pid $(pgrep lfd)    [PASS]"
                fi

                if egrep -q 'TESTING.*1"' /etc/csf/csf.conf; then
                        CSF_TESTING='CSF is in TESTING mode. This is not suitable for a production environment!         [FAIL]'
                else
                        CSF_TESTING='CSF is NOT in TEST mode.   [PASS]' 
                fi

                CSF_VERSION="$(csf -c)"
                if [ -z "$(echo "$CSF_VERSION"|grep newer)" ]; then
                        CSF_VERSION="$CSF_VERSION       [PASS]"
                else
                        CSF_VERSION="$CSF_VERSION       [FAIL]"
                fi

                echo -e "\nFirewall Installed:\n${FIREWALL}" 
                echo -e "\nFirewall Status:\n${CSF_DISABLE}" 
                echo -e "\nFirewall Test Mode:\n${CSF_TESTING}" 
                echo -e "\nFirewall LFD Status:\n${LFD_RUNNING}" 
                echo -e "\nFirewall Version Check:\n${CSF_VERSION}" 

        fi

        if which asl >/dev/null 2>&1; then

                FIREWALL="ASL   [PASS]"
                ASL_VERSION="$(asl -v)"

                echo -e "\nFirewall Installed:\n${FIREWALL}"
                echo -e "\nFirewall Version: [WARNING]\n${ASL_VERSION}\n        *** ASL has no method of programmatically returning the latest version to compare with the current one. You should enable automatic updates via its gui and/or\n            update manuall, following the instructions at http://www.atomicorp.com/wiki/index.php/Upgrading_ASL."
        fi

        if [ -z "$FIREWALL" ]; then
                if [ "$PANEL" == "Plesk" ]; then
                        echo "There does not appear to be a third party firewall installed. Plesk does have its own firewall though. You need to either install a firewall, or make sure that Plesk's firewall module is enabled.       [WARNING]"
                else
                        echo "There does not appear to be a firewall running!   [FAIL]"
                fi
        fi

}

function checkforcms(){
        if [ -z "$WORDPRESS_VERSION_LIST" ] && [ -z $JOOMLA_VERSION_LIST ]; then
                return
        else
                echo -e "\n###################################################################\n                CMS Sites\n###################################################################\n"
        fi
}

function panelversion(){
        echo -e "\n###################################################################\n        Panel and OS\n###################################################################\n"

        echo "$PANEL Info:"

        [ -d /usr/local/psa ] && cat /usr/local/psa/version
        [ -d /usr/local/cpanel ] && cat /usr/local/cpanel/version
        [ -d /usr/local/directadmin ] && /usr/local/directadmin/custombuild/build versions

        CUR_VERSION=$(cat /etc/redhat-release)
        echo -e "\nOS:"
        echo $CUR_VERSION

        LATEST=$(yum provides cent*|grep 'CentOS release'|tail -1|sed 's/^.*release-\|\.el.*$//g'|sed 's/-/\./')
        echo -e "\nLatest version provided by yum:"
        echo $LATEST


        CUR_MAJ=${CUR_VERSION%.*}
        LATEST_MAJ=${LATEST%.*}

        if [ $CUR_MAJ -lt $LATEST_MAJ ]; then
                echo -e "\nYour OS is at least one full major release older than what yum provides, which means it is pretty dated.  [FAIL]"
        else
                echo -e "\nYour OS is at the same major release as what yum provides.        [PASS]"
        fi
	
	if [ $CUR_MAJ == 4 ]; then
		echo -e "\n*************** YOUR OS IS SEVERELY OUTDATED. IT IS SO OLD THAT THE VERSION OF BASH PROVIDED CANNOT EVEN RUN THIS BASIC REPORT! EXITING. ********************		[FAIL]"
		exit
	fi
}


function checkmysql(){
        echo -e "\n###################################################################\n                        MySQL\n###################################################################\n"

        [ -d /usr/local/psa ] && mysqladmin -uadmin -p'$MYPWD' version|egrep 'version|Connec|sock|time'
        [ -d /usr/local/directadmin ] && mysqladmin -uda_admin -p'$MYPWD' version|egrep 'version|Connec|sock|time'
        [ -d /usr/local/cpanel ] && mysqladmin version|egrep 'version|Connec|sock|time'
}

panelversion
pleskDomains
cpanelDomains
wordpressversions
joomlaversions
checkforcms
checkwordpress
checkjoomla
apache
firewall
checkmysql

