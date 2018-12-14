#!/bin/bash
export PATH


function get_nodes(){
 nodes=$(oc get pods --all-namespaces -o wide |grep 0/1 |grep ing|awk '{print $NF}'|grep -v none |sort  |uniq  -c |sort -r |awk '{print $2}')
 echo ${nodes}
}


function check_node(){
  nodename=$1
  total=$(oc adm manage-node  ${nodename} --list-pods |grep ing |wc -l)
  error=$(oc adm manage-node  ${nodename} --list-pods |grep 0/1 |grep -v Off |wc -l)
  # echo ${total} ${error}
  if [ ${total} -lt 8 ];then
    total=10
  fi
  let deviation_count=${total}-6
  if [ ${error} -gt ${deviation_count} ];then
    # ssh ${nodename} "systemctl restart docker"
    # sleep 180
    # time=$(date "+%Y%m%d %H:%M:%S")
    # echo "Restart ${nodename} Docker at ${time}" >> restart_docker.txt 
    echo ${nodename}
  fi
  echo ""
}


function scale_node_pod(){
  nodename=$1
  dcs=$(oc adm manage-node $nodename --list-pods |grep -v "NAME" | awk '{print $1,$2}')
  echo "${dcs}" | while read line
  do
    project=$(echo ${line}|awk '{print $1}')
    pod=$(echo ${line}|awk '{print $2}')
    dc=$(oc describe pod ${pod}  -n ${project} |grep -E "\bdeploymentconfig=\b" |awk -F "=" '{print $2}')
    if [ -z ${dc} ];then
      kind=$(oc get pod ${pod} -n ${project} -o yaml|grep kind |grep -v "Pod" |awk -F ":" '{print $2}')
      if [ ${kind} == "DaemonSet" ];then
        continue
      else
        deploy_name=$(oc get deploy -n kong-dev -o yaml |grep -E "\s+name" |head -n 1 |awk -F ":" '{print $2}')
        curr_count=$(oc get deploy ${deploy_name} -n ${project}|tail -n 1 |awk '{print $3}')
        let new_count=${current_count}+1
        oc scale deploy ${deploy_name}  --replicas=${new_count} -n ${project}
        sleep 5
        continue
      fi
    fi
    curr_count=$(oc get dc ${dc} -n ${project} |tail -n 1|awk '{print $3}')
    let new_count=${current_count}+1
    oc scale dc ${dc} --replicas=${curr_count} -n ${project}
    sleep 1
  done
}


function restart_docker(){
  nodename=$1
  ssh ${nodename} "systemctl restart docker&&systemctl restart origin-node"
  sleep 200
}


while true
do
  echo "Start New Check..."
  oc login -u 'username' -p 'password' https://openshift.domain:8443
  nodes=$(get_nodes) 
  for node in ${nodes};do
     result=$(check_node ${node})
     if [ -z $result ];then
       # echo "${node} normat"
       continue
     else
       # echo ${node}
       scale_node_pod ${node}
       sleep 120
       restart_docker ${node}
       time=$(date "+%Y%m%d %H:%M:%S")
       echo "Restart ${node} Docker at ${time}" >> restart_docker.txt 
     fi
     sleep 5
     cat /dev/null > nohup.out
  done
done
