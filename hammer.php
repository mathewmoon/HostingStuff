<?php

function domlog(){
  if(is_dir('/usr/local/cpanel')){
    $path='/usr/local/apache/domlogs'
    exec("cut -d: -f1 /etc/userdomains|sed 's/^/\/usr\/local\/apache\/domlogs\/g'|xargs tail -n 5000|grep -v '==>'|awk '{print $1}'|sort|uniq",$domlog);
  }
  return $domlog
}

function hammerTime($domlog){
  $rbl=explode(',',file_get_contents('../bannedips.txt'));
  foreach($domlog as $client){
      if(in_array($client,$rbl)){
	echo 'found!';
      }
  
//  exec("find $path -type f|grep",$logs);

?>





