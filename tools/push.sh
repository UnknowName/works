#!/bin/bash
export PATH

SRC_REGISTRY="registry.src.cn:5000"
SRC_OPENSHIFT="https://openshift.src.cn:8443"

DEST_USER="user"
DEST_PASS="pass"
DEST_REGISTRY="registry.dest.cn"

filename=$1

function login_openshift(){
   openshift=$1
   oc logout >/dev/null
   oc login ${openshift}
}


function login_docker(){
    user=$1
    pass=$2
    registry=$3
    docker login -u ${user} -p ${pass} ${registry} 
}

if [ -z ${filename} ];then
  images=$(docker images |grep -v TAG |awk '{print $1,$2}')
  echo "${images}" |while read line
  do
    reg=$(echo ${line}|awk '{print $1}')
    tag=$(echo ${line}|awk '{print $2}'|awk -F ":" '{print $1}')
    project=$(echo ${line}|awk -F "/" '{print $2}')
    app=$(echo ${line}|awk -F "/" '{print $3}'|awk '{print $1}')
    docker tag  ${reg}:${tag} ${DEST_REGISTRY}/${project}/${app}:${tag}
    docker push ${DEST_REGISTRY}/${project}/${app}:${tag}
  done
else
  login_openshift ${SRC_OPENSHIFT}
  login_docker `oc whoami` `oc whoami -t` ${SRC_REGISTRY}
  images=$(cat ${filename}|grep -v "#" |grep -v "^$")
  echo "${images}"|while read line
  do
    project=$(echo ${line}|awk '{print $1}')
    app=$(echo ${line}|awk '{print $2}')
    docker pull ${SRC_REGISTRY}/${project}/${app}:v1
    if [ $? -ne 0 ];then
      echo "${project} ${app}" >> pull_failed_images.txt
    else
      docker tag  ${SRC_REGISTRY}/${project}/${app}:v1 ${DEST_REGISTRY}/${project}/${app}:v1
    fi
  done
  login_docker ${DEST_USER} ${DEST_PASS} ${DEST_REGISTRY}
  echo "${images}"|while read line
  do
    project=$(echo ${line}|awk '{print $1}')
    app=$(echo ${line}|awk '{print $2}')
    docker push  ${DEST_REGISTRY}/${project}/${app}:v1
  done
fi
# How to Use
# sh push.sh images.txt

# in images.txt
# project app
