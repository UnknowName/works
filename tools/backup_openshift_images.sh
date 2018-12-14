#!/bin/bash
export PATH

# How to Use
# Step1:  Run a New Registry on OpenShfit.And Expose SVC By NodePort
# Step2:  Add SRC_REGISTRY and DEST_REGISTRY InsecuryRegistry to Run Script host
# Step3:  echo "IP docker-registry.default.svc" > /etc/hosts.Add a host record
# Step4: Run this script


OPENSHIFT="https://openshift.domain.io:8443"
SRC_REGISTRY="docker-registry-default.app.domain.io"
DEST_REGISTRY="docker-registry.default.svc:5000"


function login_openshift() {
  oc login ${OPENSHIFT}
}


function login_docker() {
  docker_registry=$1
  user=$(oc whoami)
  pass=$(oc whoami -t)
  docker login -u ${user} -p ${pass} ${docker_registry}
}


function pull_openshift_all_images(){
  images=$(oc get is --all-namespaces |grep -v "jboss\|zabbix\|jenkins\|dotnet\|fis" |awk 'NR>1 {print $1, $2, $4}')
  echo "${images}" |while read line
  do
    project=$(echo ${line}|awk '{print $1}')
    app=$(echo ${line}|awk '{print $2}')
    tag=$(echo ${line}|awk '{print $3}'|awk -F "," '{print $1}')
    if [ -z ${tag} ];then
      tag="latest"
    fi
    docker pull ${SRC_REGISTRY}/${project}/${app}:${tag}
    if [ $? -ne 0 ];then
      echo "${project} ${app}:${tag}" >> pull_failed_images.txt
    fi
  done
}


function push_openshift_all_images(){
  images=$(oc get is --all-namespaces|grep -v "jboss\|jenkins\|zabbix\|dotnet\|fis" |awk 'NR>1 {print $1, $2, $4}')
  echo "${images}" |while read line
  do
    project=$(echo ${line}|awk '{print $1}')
    app=$(echo ${line}|awk '{print $2}')
    tag=$(echo ${line}|awk '{print $3}'|awk -F "," '{print $1}')
    if [ -z ${tag} ];then
      tag="latest"
    fi
    _sha_registry=$(oc get is ${app} -n ${project}  -o jsonpath="{.status.tags[0].items[0].dockerImageReference}")
    oc_hash=$(echo ${_sha_registry} | awk -F '@' '{print $2}')
    docker_hash=$(docker inspect  -f  '{{ index .RepoDigests 0 }}'  ${SRC_REGISTRY}/${project}/${app}:${tag}|awk -F '@' '{print $2}')
    if [ ${oc_hash} = ${docker_hash} ];then
       docker tag  ${SRC_REGISTRY}/${project}/${app}:${tag}   ${DEST_REGISTRY}/${project}/${app}:${tag}
       docker push ${DEST_REGISTRY}/${project}/${app}:${tag}
    else
       echo "${project} ${app}:${tag}" >> not_push_imges.txt
       echo "Not eq"
    fi
  done
}


login_openshift
if [ $? -ne 0 ];then
  echo "OC Login Failed!Exit"
  exit
fi
login_docker ${SRC_REGISTRY}
pull_openshift_all_images
login_docker ${DEST_REGISTRY}
push_openshift_all_images
