#!/bin/bash
# -*- coding: utf-8 -*-
###SCRIPT_NAME:weixin.sh###
CropID='wx4586a09d8a238d66'
Secret='70iY5xGoRepqx2L6PqX2PxoWE97oUKIUXspYA_hoKuI'
GURL="https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=$CropID&corpsecret=$Secret"
Gtoken=$(/usr/bin/curl -s -G $GURL | awk -F \" '{print $10}')
PURL="https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=$Gtoken"
function body() {
local int AppID=0           # 企业号中的应用id
local UserID=$1             # 部门成员id，zabbix中定义的微信接收者
local Msg=$2                #过滤出zabbix中传递的第三个参数
printf '{\n'
printf '\t"touser": "'$UserID'",\n'
#printf '\t"toparty": "$PartyID",\n'
printf '\t"msgtype": "text",\n'
printf '\t"agentid": "'$AppID'",\n'
printf '\t"text": {\n'
printf '\t\t"content": "'${Msg}'"\n'
printf '\t},\n'
printf '\t"safe":"0"\n'
printf '}\n'
}
msg=$(body $1 $2)
echo "${msg}"
curl --data-ascii "$msg" $PURL
printf '\n'
