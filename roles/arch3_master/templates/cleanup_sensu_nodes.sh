#!/bin/bash
#set -x

rm /tmp/nodes_to_delete*
rm /tmp/worker_nodes_to_check*

sudo -H sensu-cli client list| grep "name:" |egrep -v "worker|Launcher" > /tmp/nodes_to_delete.txt_temp
cat /tmp/nodes_to_delete.txt_temp | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" | awk -F":" '{print $2}'| sed -e 's/^[ \t]*//' > /tmp/nodes_to_delete.txt

sudo -H sensu-cli client list| grep "name:" |grep "worker" > /tmp/worker_nodes_to_check.txt_temp
cat /tmp/worker_nodes_to_check.txt_temp | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" | awk -F":" '{print $2}'| sed -e 's/^[ \t]*//' > /tmp/worker_nodes_to_check.txt

while read worker
do
  last_time=`sudo -H sensu-cli client history $worker |grep disk-usage-metrics -A2 | grep last_execution| awk -F":" '{print $2}'`;
  echo $last_time > /tmp/last_time.txt;
 #cat /tmp/last_time.txt | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" | awk -F":" '{print $2}'| sed -e 's/^[ \t]*//' > /tmp/clean_last_time.txt;
  cat /tmp/last_time.txt | sed 's/\x1b\[[0-9;]*m//g' > /tmp/clean_last_time.txt;
  last_executed_time=`cat /tmp/clean_last_time.txt`;
  current_time=`date +%s`;
  declare -i diff=$(($current_time-last_executed_time));
  if [ $diff -ge 300 ]
    then echo $worker >> /tmp/nodes_to_delete.txt
  fi;
done < "/tmp/worker_nodes_to_check.txt"

​while read line
  do curl --user "admin:seqware" -X DELETE http://localhost:4567/clients/$line;
done < "/tmp/nodes_to_delete.txt"
