#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

function check_root(){
	[[ $EUID != 0 ]] && echo -e "当前账号非ROOT(或没有ROOT权限)，无法继续操作，请获取ROOT权限（执行后会提示输入当前账号的密码）。" && exit 1
}
function setout(){
	if [ -e "/usr/bin/yum" ]
	then
		yum -y install curl gcc gcc+ make  wget net-tools
	else
		exit
		
	fi
}
function check_env(){
    yum install epel-release -y
    yum install java-1.8.0-openjdk-headless.x86_64 -y
    yum install pwgen -y
}
function install_mongodb(){
    # cd /etc/yum.repos.d/
    # touch mongodb-org.repo
    # echo "[mongodb-org-4.0]" >> mongodb-org.repo
    # echo "name=MongoDB Repository" >> mongodb-org.repo
    # echo "baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/4.0/x86_64/" >> mongodb-org.repo
    # echo "gpgcheck=1" >> mongodb-org.repo
    # echo "enabled=1" >> mongodb-org.repo
    # echo "gpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc" >> mongodb-org.repo
    # cd 
    rpm -ivh https://mirrors.aliyun.com/mongodb/yum/redhat/7/mongodb-org/4.0/x86_64/RPMS/mongodb-org-4.0.12-1.el7.x86_64.rpm
    rpm -ivh https://mirrors.aliyun.com/mongodb/yum/redhat/7/mongodb-org/4.0/x86_64/RPMS/mongodb-org-mongos-4.0.12-1.el7.x86_64.rpm
    rpm -ivh https://mirrors.aliyun.com/mongodb/yum/redhat/7/mongodb-org/4.0/x86_64/RPMS/mongodb-org-server-4.0.12-1.el7.x86_64.rpm
    rpm -ivh https://mirrors.aliyun.com/mongodb/yum/redhat/7/mongodb-org/4.0/x86_64/RPMS/mongodb-org-shell-4.0.12-1.el7.x86_64.rpm
    rpm -ivh https://mirrors.aliyun.com/mongodb/yum/redhat/7/mongodb-org/4.0/x86_64/RPMS/mongodb-org-tools-4.0.12-1.el7.x86_64.rpm
    # yum install mongodb-org -y 
    systemctl daemon-reload
    systemctl enable mongod.service
    systemctl start mongod.service
    echo "##############################mongoDB安装完成##############################"
}
function install_ela(){
    rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
    # cd /etc/yum.repos.d/
    # touch elasticsearch.repo
    # echo "[elasticsearch-6.x]" >> elasticsearch.repo
    # echo "name=Elasticsearch repository for 6.x packages" >> elasticsearch.repo
    # echo "baseurl=https://artifacts.elastic.co/packages/oss-6.x/yum" >> elasticsearch.repo
    # echo "gpgcheck=1" >> elasticsearch.repo
    # echo "gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch" >> elasticsearch.repo
    # echo "enabled=1" >> elasticsearch.repo
    # echo "autorefresh=1" >> elasticsearch.repo
    # echo "type=rpm-md" >> elasticsearch.repo
    # cd 
    rpm -ivh https://arya.valarx.com/graylog/elasticsearch-oss-6.8.2.rpm
    # yum install elasticsearch-oss -y
    read -p "设置ela集群名称:" clustername
	while [ -z "${clustername}" ]
	do
		read -p "设置Caddy用户名:" clustername
	done
    sed -i "15,18s/#cluster.name: my-application/cluster.name: ${clustername}/g" /etc/elasticsearch/elasticsearch.yml
    systemctl daemon-reload   ###重新扫描有变动的单元
    sudo systemctl enable elasticsearch.service
    sudo systemctl start elasticsearch.service
    echo "##############################elasearch安装完成##############################"
}
function install_graylog(){
    # rpm -ivh https://packages.graylog2.org/repo/packages/graylog-3.1-repository_latest.rpm
    # sudo yum install graylog-server -y
    rpm -ivh https://arya.valarx.com/graylog/graylog-3.1-repository_latest.rpm
    rpm -ivh https://arya.valarx.com/graylog/graylog-server-3.1.0-6.noarch.rpm
    secret=$(pwgen -N 1 -s 96)
    sed -i "54,67s/password_secret =/password_secret = ${secret}/g" /etc/graylog/server/server.conf
    read -p "设置graylog登陆密码：" pswd
    while [ -z "${pswd}" ]
    do
        read -p "设置graylog登陆密码：" pswd
    done
    pdd=$(echo -n ${pswd} | sha256sum)  ##生成登陆密码
    passdd=$(echo $pdd | awk '{print $1}')
    sed -i "54,67s/root_password_sha2 =/root_password_sha2 = ${passdd}/g" /etc/graylog/server/server.conf
    sed -i "101,105s/#http_bind_address = 127.0.0.1:9000/http_bind_address = 0.0.0.0:9000/g" /etc/graylog/server/server.conf
    systemctl daemon-reload
    sudo systemctl enable graylog-server.service
    sudo systemctl start graylog-server.service    
    echo "##############################graylog安装完成##############################"
}
function public_ip(){
    read -p "请输入服务器公网IP：" publicip
    while [ -z "${publicip}" ]
    do
        read -p "请输入服务器公网IP" publicip
    done
    sed -i "133,135s/#http_external_uri =/http_external_uri = http:\/\/${publicip}:9000\//g" /etc/graylog/server/server.conf
    sudo systemctl restart graylog-server.service 
}
function check_firewall(){
	if [ -e "/etc/sysconfig/iptables" ]
	then
		iptables -I INPUT -p tcp --dport 9000 -j ACCEPT
		iptables -I INPUT -p tcp --dport 27017 -j ACCEPT
		iptables -I INPUT -p tcp --dport 9200 -j ACCEPT
		iptables -I INPUT -p tcp --dport 9300 -j ACCEPT
		service iptables save
		service iptables restart
	elif [ -e "/etc/firewalld/zones/public.xml" ]
	then
		firewall-cmd --zone=public --add-port=9000/tcp --permanent
		firewall-cmd --zone=public --add-port=27017/tcp --permanent
		firewall-cmd --zone=public --add-port=9200/tcp --permanent
		firewall-cmd --zone=public --add-port=9300/tcp --permanent
        firewall-cmd --zone=public --add-port=12201/tcp --permanent
		firewall-cmd --reload
	elif [ -e "/etc/ufw/before.rules" ]
	then
		sudo ufw allow 9000/tcp
		sudo ufw allow 9200/tcp
		sudo ufw allow 9300/tcp
		sudo ufw allow 27017/tcp
	fi
    echo "##############################firewall配置完成##############################"
}

#选择安装方式
echo "------------------------------------------------"
echo "Linux + Elasearch + Graylog + Mongodb一键安装脚本(LEGM) by sooemma beta1.0"
echo "1) 安装LEGM"
echo "2) VPC网络配置公网IP"
echo "3) 安装elasearch"
echo "4) 退出"
read -p "请输入选择项：" num
case $num in
    1) 
    	check_root
    	setout && \
    	check_env && \
    	install_mongodb && \
    	install_ela && \
    	install_graylog && \
        check_firewall
    ;;
    2) 
    	public_ip 
    ;;
    3)  install_ela
        check_firewall
    ;;
    4) 
    	exit
    ;;
    *) echo '输入错误！'
esac