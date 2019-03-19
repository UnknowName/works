#!/bin/bash
export PATH

docker exec -i mongo-{{ ENV }} mongo << EOF
rsconf = {
  "_id": "rs0",
  "members": [
   {% for host in groups["mongodb"] %}
     {
       "_id": {{ loop.index0 }},
       "host":"{{ host }}"{% if loop.first %},
       "priority" : 20{% endif %}
     }{% if not loop.last %},{% endif %}

   {% endfor %}
  ]

};
rs.initiate(rsconf);
sleep(1000);
EOF
