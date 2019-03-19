#!/bin/bash
export PATH

docker exec -i mongo-{{ ENV }} mongo << EOF
use admin;
db.createUser(
  {user:"{{ MONGO_USER }}",pwd:"{{ MONGO_PASSWORD }}",
  roles:["userAdminAnyDatabase","clusterAdmin","dbAdminAnyDatabase"]}
);
sleep(2000);
db.auth('{{ MONGO_USER }}', '{{ MONGO_PASSWORD }}');
sleep(2000);
show dbs;
use {{ MONGO_INITDB }};
db.createUser({user:"{{ MONGO_INITDB_USER }}",pwd:"{{ MONGO_INITDB_PASSWORD }}",roles:["dbAdmin","readWrite"]});
EOF
