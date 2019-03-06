{%- for host in groups['mysql'] -%}
  {%- if hostvars[host]['role'] == 'master' -%}
    {%- set ip=hostvars[host]['ansible_default_ipv4']['address'] -%}
     CHANGE MASTER  TO  master_host='{{ ip }}',master_user='{{ EPEL_USER |default("epel") }}',
     master_password='{{ EPEL_PASSWORD|default("epel") }}',master_auto_position=1;
     FLUSH PRIVILEGES;
     START slave;
  {%- endif -%}
{%- endfor -%}
