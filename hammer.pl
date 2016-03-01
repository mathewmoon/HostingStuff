 
# Extract IP's from apache access logs for the last hour and matches with forum spam bot list.
# The fun work of Daniel Pearson
 
use strict;
use warnings;
use Socket;
 
# Declarations
my ($file,$list,@files,$match,$path,$sort,$line);
my $timestamp = localtime(time);
 
# Check to see if matching file exists
$list ='/root/support/listed_ip_7.txt';
 
if (-e $list) {
# Delete the file so we can download a new one if it exists
print "File Exists!";
print "Deleting File $list\n";
unlink($list);
}
sleep(5);
 
system ("wget -P /root/support http://www.danielpearson.com/listed_ip_7.txt");
 
my $dir = $ARGV[0] or die "Need to specify the log file directory\n";
$path='/var/log/messages';
open $path, "-|", "/usr/bin/tail", "-1000", "$path" or die "could not start tail on $path: $!";
 
while (my $line = <$path>) {
chomp $line;
if ($line =~  
m/(?!0+\.0+\.0+\.0+$)(([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5])\.([01]?\d\d?|2[0-4]\d|25[0-5]))/g) 
{
my $ip = $1;
$ips{$ip} = $ip;
                        }
                }
}
open ("files","$list");
while (my $sort = <files>) {
chomp $sort;
foreach my $key (sort keys %ips) {
if ($key =~ $sort) {
my $match =qx(iptables -nL | grep $key 2>&1);
chomp $match;
if ($match =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/) {
print "Already banned $key\n";
}
else {
system ("iptables -A INPUT -s $key -j DROP");
open my $fh, '>>', '/root/support/banned.out';
print "Match Found we need to block it $key\n";
print $fh "$key:$timestamp\n";
close $fh;
                        }
                }
        }

}
