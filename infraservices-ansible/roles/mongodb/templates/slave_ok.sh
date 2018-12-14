#!/bin/bash
export PATH
docker exec -i mongo mongo << EOF
rs.slaveOk();
show dbs;
show dbs;
EOF
