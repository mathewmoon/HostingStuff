#!/bin/bash
####################################################################################################################################################
#                                                                                                                                                  #
#          Finds those pesky base64 injections and can chmod 000, rm, or just tell us about the files, what commands they contain, etc...          #
#          After dealing with the file itself, the script goes on to attemp to find the origin of it, or at least let us know what was going on    #
#          around the time that it was first seen. Far from perfect, but hopefully usable. --Mathew                                                #
#                                                                                                                                                  #
#####################################################################################################################################################


#get options

usage=`cat<<'END'
   findbase64 -- Searches files for a common php exploit, creates a report and will optionally chmod to 000 the files that are found
   Usage findbase64 [-a] [-m] [-d 'directory']
   options: -s             Remove any symlinks that point to a directory outside of the user's home
            -S             Same as -s, but also removes all broken symlinks
            -a             Check all public_html directories
            -u [user]      Start in specific directory
            -m             chmod to 000 any files that are a definite matches
            -h             Show this help file
END
`

while getopts "Ssamu:" option
do
        case "${option}"
        in
                   S) NUKESYM=true
                      ;;
                   s) SYMS=true
                      ;;
                   a) HTML=true 
                      ;;
                   u) USER=${OPTARG} 
                      ;;
                   m) MOD=true
                      ;;
                   h) printf "$usage"
                      exit
                      ;;
                   ?)printf "$usage"
                      exit
                      ;;
           esac
done

if [[ $SYMS ]] && [[ $NUKESYM ]]
then
  echo -e "Invalid combination of options (-s and -S). Please select one, the other, or none at all or -h for help"
  exit
fi

if [[ ! $USER ]] && [[ ! $HTML ]]
then
  echo "Missing required options. Use -h for complete list of options"
  exit
fi  

############################################################################################################
#                          Functions that we need                                                          #
############################################################################################################

#Remove everything in a user's tmp directory
clean_tmp(){
  echo -e "Cleaning out temp directories.........."
  echo -e "\nCleaning out temp directories.........." >> exploitscanner.log
  if [[ $HTML == true ]]
  then
    for user in $(cat /etc/trueuserowners|cut -d \: -f1|grep -v '#')
    do
      sudo rm -r "/home/$user/tmp/*" 2>/dev/null
      if [[ $? == 0 ]]
      then
        echo "Cleaned /home/$user/tmp"
        echo "Cleaned /home/$user/tmp" >> exploitscanner.log
      elif [[ $? != 0 ]]
      then
        echo "/home/$user/tmp was empty."
        echo "/home/$user/tmp was empty." >> exploitscanner.log
      fi
    done
    else
      return
    fi  
      echo -e "Done Cleaning ..... \n"
      echo -e "Done Cleaning ..... \n" >> exploitscanner.log
}
  
#look for evil symlinks an remove them

killit(){
        #remove broken symlinks
        if [[ ! -e $(readlink 2>/dev/null "$1") ]]
        then
            echo -e "WARNING: $1 is a broken symlink to $(readlink 2>/dev/null "$1") and has been removed." 
            echo -e "WARNING: $1 is a broken symlink to $(readlink 2>/dev/null "$1") and has been removed." >> exploitscanner.log
            rm -f "$1" 2>/dev/null 
            continue
        fi
        #if the link points to a system dir delete it
        username=$(echo $(readlink 2>/dev/null $line)|cut -d '/' -f3)
        if [[ $(echo $1 | grep -E 'root|etc|dev|bin|usr|lib|home|boot|media|opt|proc|sbin|selinux|srv|sys|var') ]] 
        then
            echo -e "WARNING: $1 is a symlink to system directory $(readlink 2>/dev/null "$1") and has been removed." 
            echo -e "WARNING: $1 is a symlink to system directory $(readlink 2>/dev/null "$1") and has been removed." >> exploitscanner.log
            rm -f "$1" 2>/dev/null
            continue
        fi
}

nuke_syms(){
  export -f killit
  if [[ $SYMS != true ]] && [[ $NUKESYM != true ]]
  then
    return
  fi
  
  if [[ $HTML == true ]]
  then
    echo -e "\nLooking for evil symlinks that point to system directories. We will attempt to remove any that are found........."
    echo -e "\nLooking for evil symlinks that point to system directories. We will attempt to remove any that are found.........." >>exploitscanner.log
    for user in $(cat /etc/trueuserowners|cut -d \: -f1|grep -v '#')
    do
      find /home/*/public_html -type l |while read line
      do
        killit "$line"
      done
    done
    echo -e "Done looking for symlinks...\n" >>exploitscanner.log
    echo -e "Done looking for symlinks...\n"
  fi
}

grepdirs(){
  echo "Grepping -Rl "$1"\n";
  grep -Rl 'eval(base64_decode(' "$1" >>exploitscanner.tmp
} 

print_dirs(){
  echo -e "Making a list of files that contain eval(base64_decode())..........">>exploitscanner.log
  echo -e "Making a list of files that contain eval(base64_decode()).........."
  while read line
  do
    echo FOUND: $line
    echo FOUND: $line>>exploitscanner.log
  done< exploitscanner.tmp
  echo -e "End of List...\n">>exploitscanner.log;
  echo -e "End of List...\n"
} 

#set the directories to scan
get_dirs(){
  if [[ -e '/etc/trueuserowners' ]]
  then
    if [[ $HTML == true ]]
    then
      for username in $(cat /etc/trueuserowners|cut -d \: -f1|grep -v '#');
      do
        echo "found user $username";
        grepdirs "/home/$username/public_html"
      done;
    elif [[ $USER ]]
    then
      grepdirs "/home/$USER/public_html"
    else
      echo "No directory specified. You must specify -a for scanning all user's home directories, or -u [username] for a specific user"
      exit;
    fi
  fi
  
  if [[ -e /usr/local/psa/version ]]
  then
    if [[ $HTML == true ]]
    then
      for username in $(ls '/var/www/vhosts'|grep -v 'chroot');
      do
        echo "found user $username";
        grepdirs "/var/www/vhosts/$username"
      done;
    elif [[ $USER ]]
    then
      grepdirs "/var/www/vhosts/$USER"
    else
      echo "No directory specified. You must specify -a for scanning all user's home directories, or -u [username] for a specific user"
      exit;
    fi
  fi
}



#find base64 commands
find_base(){
    if [[ $(echo $(file $1)|egrep 'tar|binary|executable') ]]
    then
        echo -e "$1 is a tarball,binary, or some other file that cannot be searched with grep\n"
        echo -e "$1 is a tarball,binary, or some other file that cannot be searched with grep\n">>exploitscanner.log
    fi

    file=$(echo $( < $1 )|sed 's/\s\|\n\|\ //g'|sed 's/;/;\n/g')
    #find_shell $file $1
    for line in $file
      do
        is_var=false
        is_shell=false
        string=$(echo "$line"|grep -n 'eval(base64_decode')
        code=${string##*base64_decode\(};
        #this is the finished product, the actual string in the base64() function
        code=$(echo ${code%%\)*} | sed 's/"//g' | sed "s/'//g");
        shell=$(echo "$code"|base64 -d 2>/dev/null)

        #sort out the huge blocks of code
        if [[ `echo ${#code}|awk '{print length}'` > 300 ]] 
        then
          echo -e "$1 ;contains base64 code that is too long to show here. You sould look at this manually."  >>exploitscanner.log
          echo -e "$1 contains base64 code that is too long to show here. You sould look at this manually."
          is_long=true
        fi  

        if [[ `echo ${#code}|awk '{print length}'` < 300 ]] 
        then
          #look for functions that have a variable instead of a static string passed to it;
          if [[ ${code:0:1} == $ ]] && [[ $is_long != true ]]
          then
            echo -e "POSSIBLE MATCH:; $1 ;contains an eval(base64()) command that has the variable $code passed to it." >> exploitscanner.log
            echo -e "POSSIBLE MATCH: $1 contains an eval(base64()) command that has the variable $code passed to it." 
            is_var=true
           fi
          
          #look for shell commands executed with php functions
          if [[ $(echo "$shell" | grep 2>/dev/null -E 'wget|passthru|shell_exec|exec|system|sudo') ]] && [[ $is_var != true ]] && [[ $is_long != true ]]
          then
            echo -e "DEFINITE MATCH:; $1 ;contains a shell command $shell">>exploitscanner.log
            echo -e "DEFINITE MATCH: $1 contains a shell command $shell"
            is_shell=true
          fi
          
          if [[ ! $is_long ]] && [[ ! $is_var ]] && [[ ! $is_shell ]] && [[ -n $shell ]]
          then  
            echo -e "POSSIBLE MATCH:; $1 ;contains base64 code that translates into $shell"  >>exploitscanner.log
            echo -e "POSSIBLE MATCH: $1 contains base64 code that translates into $shell"
          fi
        fi
    done
}

#find shell a shell 
find_shell(){
  if [[ $1 == "*404.php" ]] && [[ $(grep -E 'session|ini_get|ini_set|password' "$1") != '' ]]
  then
    shell=true
  fi

  if [[ $1 == "*.htaccess" ]] && [[ $(grep 'fuck' "$1") ]]
  then
    shell=true
  fi
      
  if [[ $(grep -E 'hacked|fuck_v(B|b)ulletin|fuck_joomla|hacked\ by|fuck_w0rdPress|fuck_wordpress|fuck_j|Lagripe|(H|h)acker-man|Priv8\ Php|(D|d)amane2011|abdou2010new\@hotmail.fr|(S|s)yrian\ shell|(S|s)yrianshell' $1) ]]
  then
    $shell=true;
  fi
      
  if [[ $shell == true ]]
  then
    echo -e "DEFINITE MATCH:; "$1" ;Is a shell."
  fi
}
   
# Start reading the list and get the actual code from the files in the list then print them to a log
find_badstuff(){
  echo -e " \nFinding Dirty Files..........">>exploitscanner.log
  echo -e " \nFinding Dirty Files.........."
  while read line;
    do
      find_base "$line"
  done<exploitscanner.tmp
  echo -e "End of File List...\n">>exploitscanner.log
  echo -e "End of File List...\n"
}

#Chmod all of the definite matches
chmoddem(){
  if [[ $MOD != true ]]
  then
    return;
  fi  
  echo -e "\nCreating a list of definite matches that have been chmodded to 000 for safety.........." >>exploitscanner.log
  echo -e "\nCreating a list of definite matches that have been chmodded to 000 for safety.........."
  while read line
  do
    file=$(echo $line|grep 'DEFINITE'|cut -d \; -f2)
    if [[ $(echo $line|grep 'DEFINITE'|awk '{print $1}') == 'DEFINITE' ]] && [[ $(echo $(ls -l $file)|cut -d \. -f1) != '----------' ]]
    then
        chmod 000 "$file"
        if [[ $? == 0 ]]
        then
          echo "$(ls -l $file)" >>exploitscanner.log
        else
          echo "$file ;could ;not ;be ;chmodded. ;Maybe ;it\'s ;chattered???">>exploitscanner.log
        fi
    fi
  done<exploitscanner.log
  echo -e "\nDone Chmodding...\n">>exploitscanner.log
  echo -e "\nDone Chmodding...\n"
}  

#######################################################################################################################
#                         End of Functions                                                                            #
#######################################################################################################################
rm exploitscanner.log 2>/dev/null
rm exploitscanner.tmp 2>/dev/null
echo -e "###################################################################\nKnownHost exploit scanner run on `date` \n###################################################################"
echo -e "###################################################################\nKnownHost exploit scanner run on `date` \n###################################################################">>exploitscanner.log
clean_tmp
nuke_syms
get_dirs
print_dirs
find_badstuff
chmoddem
sed -i 's/\;//g' exploitscanner.log
echo "Scan completed. Results are printed to exploitscanner.log ."
rm exploitscanner.tmp 2>/dev/null
rm $0 2>/dev/null
exit 0;
