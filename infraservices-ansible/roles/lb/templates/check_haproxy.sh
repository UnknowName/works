#!/bin/bash
export PATH

ps aux |grep haproxy|grep -v grep |grep -v  sh >/dev/null
result=$(echo $?)
if [ $result -ne 0 ];then
  systemctl stop keepalived
  exit 10
fi
