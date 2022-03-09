#!/bin/bash

set -ue

USERNAME=xxxxxxxxxxxxx

HOSTS='
vmftest1-pcww.japaneast.cloudapp.azure.com
vmftest2-pcww.japaneast.cloudapp.azure.com
vmftest3-pcww.japaneast.cloudapp.azure.com
vmftest1-4tqb.japaneast.cloudapp.azure.com
vmftest2-4tqb.japaneast.cloudapp.azure.com
vmftest3-4tqb.japaneast.cloudapp.azure.com
'

for host in $HOSTS; do
  echo $HOSTS | xargs -n 1 echo ping -i 0.2 -c 50 | ssh "${USERNAME}@${host}" > "${host}.log"
done

