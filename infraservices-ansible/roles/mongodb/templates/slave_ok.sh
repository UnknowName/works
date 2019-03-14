#!/bin/bash
export PATH
docker exec -i mongo-{{ ENV }} mongo << EOF
rs.slaveOk();
show dbs;
show dbs;
EOF
