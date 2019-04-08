#!/bin/bash
# -*- coding: utf-8 -*-
###SCRIPT_NAME:weixin.sh###
CropID='wx4586a09d8a238d66'
Secret='70iY5xGoRepqx2L6PqX2PxoWE97oUKIUXspYA_hoKuI'
GURL="https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=$CropID&corpsecret=$Secret"
Gtoken=$(/usr/bin/curl -s -G $GURL | awk -F \" '{print $10}')
PURL="https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=$Gtoken"
Msg=$2
function body() {
local int AppID=0           # 企业号中的应用id
local UserID=$1             # 部门成员id，zabbix中定义的微信接收者
echo '{'
echo '"touser": "'$UserID'",'
#printf '\t"toparty": "$PartyID",\n'
echo '"msgtype": "text",'
echo '"agentid": "'$AppID'",'
echo '"text": {'
echo -e '"content": "'${Msg}'"'
echo '},'
echo '"safe":"0"'
echo '}'
}
msg=$(body $1 $2)
echo "${msg}"
curl --data-ascii "$msg" $PURL
printf '\n'
