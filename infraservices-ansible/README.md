# 基础服务Ansible使用指南

## 环境依赖

- 最少准备三台机器，并可以通过公钥登陆。如果需要安装LB，还需要额外二台机器
  
- 主机需要配置静态IP
  
- 基于Docker以及Docker-compose实现,窗口网络为Host,数据默认持久化至/data目录
  
- 安装LB时，需要所有的组信息，但可以留空。比如不安装elas,但是清单文件elas组需要存在，因为会自动生成HAProxy文件时会用到这些信息

- 安装Ansible

  ```bash
  # 安装Ansible
  yum install ansible -y
  ```

## 使用指南

参照[hosts.example](./hosts.example)，新建`Ansible`主机清单文件。

```bash
# 一键安装所有,以下服务基于Docker+Docker-compose，网络均使用host模式
# FastDFS集群
# MongoDB3.6 复制集，
# MySQL5.7主从
# Kafka2.12集群，
# RabbitMQ3.6集群，
# Elastcsearch5.6集群
# Cassandra集群
# Hazelcast集群
ansible-playbook -i hosts config.yaml -vv
```

按所需要安装，则需要自己定义yaml文件，如

```bash
# 只安装Elas
cat elas.yaml
- hosts: elas
  roles:
    - prepare
    - elas
ansible-playbook -i hosts elas.yaml -vv
```

## 安装完成后的默认信息(如果相关变量未指定)

- MySQL
  - Version: 5.7
  - User/Password: root/mysql

- MongoDB Replicatin Set
  - Version: 3.6

- RabbitMQ Cluster
  - Version: 3.6
  - User/Password: guest/guest
  
- Elastcisearch Cluster
  - Version: 5.6
  - User/Password: None

- Cassandra Cluster
  - Version: 3.9
  - User/Password: None
  
- Kafka Cluster
  
  - Version: 2.12
  
  - User/Password: None
  
- Redis Replicastion Sent
  
  - Version: 4
  - Password: auth.env.user

## 其他事宜

- 如果需要修改版本信息,只需要修改各`roles/tmplates`下面的`docker-compose`文件的引用的`image`的`Tag`即可.但不保证该playbook仍然可用.

- 通过Firewalld来实现安全控制

- 默认允许宿主机所在网段的24位子网主机访问(比如172.16.0.0/24)
  
- 暂时不支持服务器具有多网卡的情形