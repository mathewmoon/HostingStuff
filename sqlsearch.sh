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



















