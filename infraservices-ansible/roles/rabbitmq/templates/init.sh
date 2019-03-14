{%- set num=groups['rabbitmq']|length -%}
#!/bin/bash

docker exec -i rabbitmq-{{ ENV }}  bash << EOF
rabbitmqctl cluster_status
rabbitmqctl set_policy ha-all "." '{"ha-mode":"exactly","ha-params":{{ num }},"ha-sync-mode":"automatic"}'
EOF
