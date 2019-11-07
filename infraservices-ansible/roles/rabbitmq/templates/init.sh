{%- set num=groups['rabbitmq']|length -%}
#!/bin/bash

# 设置HA模式，副本数为集群个数，设置队列失效时间为7天。
docker exec -i rabbitmq-{{ ENV }}  bash << EOF
rabbitmqctl cluster_status
rabbitmqctl set_policy haAllAutoDelete "."  \
'{"ha-mode":"exactly","ha-params":{{ num }}, "message-ttl":604800000, "ha-sync-mode":"automatic", "queue-mode":"lazy", "expires":604800000}'
EOF