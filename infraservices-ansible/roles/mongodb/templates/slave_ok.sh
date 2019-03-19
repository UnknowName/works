#!/bin/bash
export PATH
docker exec -i mongo-{{ ENV }} mongo << EOF
use admin;
db.auth('{{ MONGO_USER }}','{{ MONGO_PASSWORD }}');
rs.slaveOk();
show dbs;
show dbs;
EOF
