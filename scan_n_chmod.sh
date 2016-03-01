
#Scans for files, saves the filenames to a list, chmods the files, creates a log of the chmodded files to show the customer. For debugging use -v option with clamscan instead of -i. This can create very
#large files though, you have been warned --Mathew */

#${1} is name of directory to start scan or pass no args and execute from the working directory.
clamscan -ir ${1}>>${2}/clamscan.log;

if [[ $(grep "FOUND" ${2}/clamscan.log) ]]
then
#	echo -e "\n################## Infected files #########################\n">>${2}/clamscan.log
#	for file in `grep FOUND ${2}/clamscan.log|awk '{print $1}'|sed 's/\://g'|sed 's/\ /\\ /g'`; do echo $file>>${2}/clamscan.log; done;
	echo -e "\n################# Changing file permissions to 000 #########################">>${2}/clamscan.log
	for file in `grep FOUND ${2}/clamscan.log|grep -v '/mail/' |awk '{print $1}'|sed 's/\://g'|sed 's/\ /\\ /g'`; do chmod 000 $file; done;
	for file in `grep FOUND ${2}/clamscan.log|grep -v '/mail/' |awk '{print $1}'|sed 's/\://g'|sed 's/\ /\\ /g'`; do ls -l $file|awk '{print $1,$9}'>>${2}/clamscan.log; done;
fi
sudo rm $0;
