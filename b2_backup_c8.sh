#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
cat << "EOF"
Author: M1Screw
Github: https://github.com/M1Screw/Airport-toolkit                               
EOF
echo "B2 Cloud Storage Backup script for LNMP running on CentOS Stream 8 x86_64"
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script!"; exit 1; }

#config
backup_name=""
b2_app_key_id=""
b2_app_key=""
b2_bucket_name=""
db_name=""
db_password=''
db_user=""
db_host=""
website_dir=""
compress_method="" #gzip or zip

do_pre_config(){
    dnf update -y
    dnf install gzip zip tar -y
    pip3 install b2
    pip3 install importlib-metadata==3.10.1
    ln -s /usr/local/bin/b2 /usr/bin/b2
}

do_db_export(){
    if [[ ${compress_method} == "gzip" ]]; then
        db_file_sql=$(date +'%Y-%m-%d-%H-%M-%S')-$backup_name.sql
        db_file_name=$(date +'%Y-%m-%d-%H-%M-%S')-$backup_name-db.gz
        mysqldump -u $db_user -p$db_password -h $db_host $db_name > $db_file_sql
        gzip -c $db_file_sql > $db_file_name
        rm $db_file_sql
    elif [[ ${compress_method} == "zip" ]]; then
        db_file_name=$(date +'%Y-%m-%d-%H-%M-%S')-$backup_name-db.zip
        mysqldump -u $db_user -p$db_password -h $db_host $db_name | zip -qq > $db_file_name
    else
        echo -n "Unknown compress method"
        exit 0
    fi
}

do_pack_website(){
    if [[ ${compress_method} == "gzip" ]]; then
        website_file_name=$(date +'%Y-%m-%d-%H-%M-%S')-$backup_name-web.tar.gz
        tar -czf $website_file_name $website_dir
    elif [[ ${compress_method} == "zip" ]]; then
        website_file_name=$(date +'%Y-%m-%d-%H-%M-%S')-$backup_name-web.zip
        zip -rqq $website_file_name $website_dir
    else
        echo -n "Unknown compress method"
        exit 0
    fi
}

do_upload_b2(){
    b2 authorize-account $b2_app_key_id $b2_app_key
    b2 upload_file $b2_bucket_name $(pwd)/$website_file_name $website_file_name
    b2 upload_file $b2_bucket_name $(pwd)/$db_file_name $db_file_name
    rm $website_file_name
    rm $db_file_name
}

if [[ $1 == "config" ]]; then
    do_pre_config
    exit 1
fi
if [[ $1 == "backup" ]]; then
    do_db_export
    do_pack_website
    do_upload_b2
    exit 1
fi
