#!/bin/bash
source /etc/profile
export PATH
set -e


CURRENT_YEAR=$(date +%Y)
BACKUP_MONTH=$(date --date "7 month ago" +%Y%m)
DATADIR="/mysql/mysqldata"
BASE_BACKUP_DIR="/mysql/baseBackup"
TABLES_BACKUP_DIR="/mysql/tablesBackup"
DB_NAME="database"
# EXCLUDE_TABLES="guard_pay_request,guard_refund_request,${CURRENT_YEAR}"

SRC_HOST="128.0.255.2"
SRC_PORT="3307"
SRC_USER="root"
SRC_PASSWORD="password"

DEST_HOST="127.0.0.1"
DEST_PORT="3306"
DEST_USER="root"
DEST_PASSWORD="password"

START_MYSQL_CMD="systemctl start mysqld"
STOP_MYSQL_CMD="systemctl stop mysqld"

# 备份基础表
function backup_base_tables() {
  echo -e "will execute: rm -rf ${BASE_BACKUP_DIR}\nWait 20 seconds"
  sleep 2
  if [ ${BASE_BACKUP_DIR} == "/" ];then
      echo "ERROR!!!BASE_BACKUP_DIR is /"
      exit 20
  fi
  rm -rf ${BASE_BACKUP_DIR}
  xtrabackup  --host=${SRC_HOST} --port=${SRC_PORT} --user=${SRC_USER} --password=${SRC_PASSWORD} --compress\
              --backup --tables-exclude=${EXCLUDE_TABLES} --target-dir=${BASE_BACKUP_DIR} --datadir=${DATADIR}
}


# 还原基础表
function restore_base_tables() {
  eval ${STOP_MYSQL_CMD}
  echo "Will Execute rm -rf ${DATADIR}"
  sleep 20
  rm -rf ${DATADIR}/*
  xtrabackup --decompress --target-dir=${BASE_BACKUP_DIR}
  xtrabackup --prepare --target-dir=${BASE_BACKUP_DIR}
  xtrabackup --move-back --target-dir=${BASE_BACKUP_DIR} --datadir=${DATADIR}
  eval ${START_MYSQL_CMD}
}


function backup_history_tables() {
  show_sql="USE ${DB_NAME};SHOW TABLES"
  tables=$(mysql -h ${SRC_HOST} -P${SRC_PORT} -u${SRC_USER} -p${SRC_PASSWORD} -e "${show_sql}" 2>/dev/null|grep ${BACKUP_MONTH})
  backup_tables=$(echo ${tables}|sed 's/[ ][ ]*/,/g')
  if [ $1 == "backup" ];then
      innobackupex --host=${SRC_HOST} --port=${SRC_PORT} --user=${SRC_USER} --password=${SRC_PASSWORD} \
                   --include=${backup_tables}   ${TABLES_BACKUP_DIR}
  elif [ $1 == "restore" ];then
    restore_tables=$(echo ${backup_tables}|sed 's/,/\t/g')

    # Step1: 准备备份文件，应用日志
    dirs=$(ls -l ${TABLES_BACKUP_DIR}|grep ${CURRENT_YEAR}|awk '{print $NF}')
    for dir in ${dirs};
    do
      # echo "apply redo log in ${dir}"
      innobackupex --apply-log --export ${TABLES_BACKUP_DIR}/${dir}
    done

    # Step2: 在目标数据库上创建具有相同表结构的表
    for table in ${restore_tables};
    do
      echo "${table}"
      # 导出源库的表结构
      mysqldump -h${SRC_HOST} -P${SRC_PORT} -u${SRC_USER} -p${SRC_PASSWORD} -d ${DB_NAME} ${table} > create_table.sql
      mysql -h${DEST_HOST} -P${DEST_PORT} -u${DEST_USER} -p${DEST_PASSWORD} ${DB_NAME} < create_table.sql
      alter_sql="USE ${DB_NAME};ALTER TABLE ${table} DISCARD TABLESPACE;"
      mysql -h${DEST_HOST} -P${DEST_PORT} -u${DEST_USER} -p${DEST_PASSWORD} -e "${alter_sql}"
    done

    # Step3: 停止MySQL, 复制ibd文件
    eval ${STOP_MYSQL_CMD}
    for dir in ${dirs};
    do
      CP=$(which cp)
      ${CP} ${TABLES_BACKUP_DIR}/${dir}/${DB_NAME}/*.ibd  ${DATADIR}/${DB_NAME}
    done
    chown -R mysql:mysql ${DATADIR}/${DB_NAME}

    # Step4: 启动MySQL，导入表空间
    eval ${START_MYSQL_CMD}
    sleep 5
    for table in ${restore_tables};
    do
      _import_sql="USE ${DB_NAME};ALTER TABLE ${table} IMPORT TABLESPACE;"
      mysql -h${DEST_HOST} -P${DEST_PORT} -u${DEST_USER} -p${DEST_PASSWORD} -e "${_import_sql}"
    done
    # Step4: 清理文件
    # file_dir=$(ls -l ${TABLES_BACKUP_DIR}|grep ${CURRENT_YEAR}|awk '{print $NF}')
    # cd ${TABLES_BACKUP_DIR} && rm -rf ${file_dir}
  else
    echo "Unkonw Operaton"
  fi
}


function check_data() {
   show_sql="USE ${DB_NAME};SHOW TABLES"
   tables=$(mysql -h ${SRC_HOST} -P${SRC_PORT} -u${SRC_USER} -p${SRC_PASSWORD} -e "${show_sql}" 2>/dev/null|grep ${BACKUP_MONTH})
   eq = "true"
   for table in ${tables};
   do
      count_sql="USE ${DB_NAME};SELECT COUNT(*) FROM ${table};"
      src_count=$(mysql -h ${SRC_HOST} -P${SRC_PORT} -u${SRC_USER} -p${SRC_PASSWORD} -e "${count_sql}" | grep -v "COUNT")
      dest_count=$(mysql -h ${SRC_HOST} -P${SRC_PORT} -u${SRC_USER} -p${SRC_PASSWORD} -e "${count_sql}" | grep -v "COUNT")
      if [ ${src_count} -ne ${dest_count} ];then
        eq = "false"
      fi
      echo "${table}  SrcCount: ${src_count}  dest_count: ${dest_count}" >> count_record.txt
   done
   echo ${eq}
}

# Init Files
echo "" > count_reocrd.txt
echo "" > create_table.sql

# Backups Tables
TABLES_BACKUP_DIR="/mysql/tablesBackup"

# Backup or restore Table.Recommend one host backup, another host restore
# backup_history_tables backup|resotre
backup_history_tables restore

# Check Data
eq=$(check_data)
if [ ${eq} == "true" ];the
  file_dir=$(ls -l ${TABLES_BACKUP_DIR} | grep ${CURRENT_YEAR}|awk '{print $NF}')
  cd ${TABLES_BACKUP_DIR} && rm -rf ${file_dir}
fi