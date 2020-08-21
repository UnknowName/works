#!/bin/bash
export PATH

monitor_consul="{{ monitor_server }}"
host_ipaddr=$(ip addr | awk '/scope global noprefixroute/' | awk '{print $2}' | awk -F '/' '{print $1}')
host_name=$(hostname)

curl -v -H 'Content-Type: application/json' -X PUT \
     --data '{"id":"'"${host_name}"'", "name": "'"${host_name}"'","address": "'"${host_ipaddr}"'","port": 9100,"tags": ["prod","prome","node"],"checks": [{"http": "http://'${host_ipaddr}':9100/metrics","interval": "35s"}]}' \
     http://${monitor_consul}:8500/v1/agent/service/register

# Unregister
# curl -v -X PUT http://${monitor_consul}:8500/v1/agent/service/deregister/${host_name}