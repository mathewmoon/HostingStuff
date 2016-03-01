#runs SMART test and prints output of specific line to file and stdout
#var passed to script is the exact name of the spec you are looking for (ie:Raw_Read_Error_Rate,Start_Stop_Count,etc.....)

while [ 1 == 1 ]
do
echo "`smartctl -d sat -a /dev/sdb|grep ${1}|awk '{print $1,$9,$10}'`-------- `date`">>/var/log/checkdisk.log
echo "`smartctl -d sat -a /dev/sdb|grep '${1}'|awk '{print $1,$9,$10}'`-------- `date`"
sleep 5m;
