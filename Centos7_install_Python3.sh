#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
sudo yum -y groupinstall "Development tools"
sudo yum -y install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel libffi-devel 
sudo wget https://www.python.org/ftp/python/3.7.0/Python-3.7.0a1.tar.xz 
sudo tar -xvJf  Python-3.7.0a1.tar.xz 
sudo mkdir -p /usr/local/python3
cd Python-3.7.0a1 
sudo ./configure --prefix=/usr/local/python3
sudo make && make install
sudo ln -s /usr/local/python3/bin/python3 /usr/bin/python3 
sudo ln -s /usr/local/python3/bin/pip3 /usr/bin/pip3
echo "安装完成" 
