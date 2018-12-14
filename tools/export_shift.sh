#!/bin/bash
export PATH

SRC_OPENSHIFT="https://openshift.vpclub.io:8443"

project=$1
src_env=$2
dest_env=$3


if [ -z ${src_env} ];then
  src_env='dev'
fi

if [ -z ${dest_env} ];then
  dest_env='stage'
fi

function login_openshift() {
  oc login $1
  user=$(oc whoami)
  pass=$(oc whoami -t)
}


function export_project(){
 oc get project  ${project} -o yaml \
 | sed '/creationTimestamp/d' \
 | sed "s/${src_env}/${dest_env}/g" \
 | sed '/resourceVersion/d' > ${project}/${project}_ns.yml
}


function export_dc(){
  oc get dc -n ${project} -o yaml \
  | sed -n '1,/^status:/p' \
  | head -n -1 \
  | sed '/uid/d' \
  | sed '/selfLink/d' \
  | sed '/resourceVersion/d' \
  | sed '/creationTimestamp/d'  \
  | sed "s/${src_env}/${dest_env}/g" \
  | sed '/generation/d'  > ${project}/${project}_dc.yml

}


function export_svc() {
  oc get svc -n ${project} -o yaml \
  | sed -n '1,/^status:/p' \
  | sed '/uid/d' \
  | sed '/selfLink/d' \
  | sed '/resourceVersion/d' \
  | sed '/creationTimestamp/d'  \
  | sed "s/${src_env}/${dest_env}/g" \
  | sed '/generation/d' \
  | sed "/clusterIP/d"  > ${project}/${project}_svc.yml
}


function export_router() {
  oc get route  -n ${project} -o yaml \
  | sed -n '1,/^status:/p' \
  | head -n -4 \
  | sed '/uid/d' \
  | sed '/selfLink/d' \
  | sed '/resourceVersion/d' \
  | sed '/creationTimestamp/d'  \
  | sed '/generation/d' \
  | sed "/clusterIP/d" \
  | sed "s/${src_env}/${dest_env}/g" \
  | sed "/host/d"  > ${project}/${project}_router.yml
}


function export_image(){
  images=$(oc get is -n  ${project} |awk -F "5000" '{print $2}'|awk '{print $1":"$2}'|grep /)
  echo "${images}" |while read line
  do
   image=${line}
   echo  ${SRC_REGISTRY}${image}
   docker pull ${SRC_REGISTRY}${image}
   docker tag ${SRC_REGISTRY}${image} ${DEST_REGISTRY}${image}
  done
}


function export_configmap() {
  oc get cm -n ${project} -o yaml \
  | sed "s/${src_env}/${dest_env}/g" > ${project}/${project}_configmap.yml
}


function export_user(){
  oc get user  -o yaml \
  | sed "s/${src_env}/${dest_env}/g" > ${project}/${project}_user.yml
}



function export_privilege(){
  oc get rolebindings -n ${project}  -o yaml \
  | sed "s/${src_env}/${dest_env}/g" > ${project}/${project}_privilege.yml
}


function push_images(){
	images=$(docker images |grep ${DEST_REGISTRY}|awk '{print $1":"$2}')
	echo "${images}" |while read line
        do
	 docker push ${line}
	done
}



# Export 
login_openshift  ${SRC_OPENSHIFT}
mkdir ${project}
export_project
export_configmap
export_dc
export_svc
export_user
export_privilege


#
# sh export_shift.sh moses-dev

# Import
# oc create --filename ${project} 

