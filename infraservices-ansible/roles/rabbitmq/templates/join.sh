#!/bin/bash


docker exec -i rabbitmq-{{ ENV }} bash << EOF
rabbitmqctl stop_app
rabbitmqctl join_cluster rabbit@rabbit1
rabbitmqctl start_app
EOF
