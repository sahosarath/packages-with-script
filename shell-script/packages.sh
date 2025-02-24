
jenkins 
---------
yum install java-11-openjdk-devel
update-alternatives --config java
yum install wget
wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
yum repolist
yum install jenkins
systemctl start jenkins
systemctl status jenkins
systemctl enable jenkins
===================================================
Pluggins
===================================================
#! /bin/bash
url=http://3.111.253.246:8080

user='sarath'
password='Saho1995@'

cookie_jar="$(mktemp)"
full_crumb=$(curl -u "$user:$password" --cookie-jar "$cookie_jar" $url/crumbIssuer/api/xml?xpath=concat\(//crumbRequestField,%22:%22,//crumb\))
arr_crumb=(${full_crumb//:/ })
only_crumb=$(echo ${arr_crumb[1]})

# MAKE THE REQUEST TO DOWNLOAD AND INSTALL REQUIRED MODULES
curl -X POST -u "$user:$password" $url/pluginManager/installPlugins \
  -H 'Connection: keep-alive' \
  -H 'Accept: application/json, text/javascript, */*; q=0.01' \
  -H 'X-Requested-With: XMLHttpRequest' \
  -H "$full_crumb" \
  -H 'Content-Type: application/json' \
  -H 'Accept-Language: en,en-US;q=0.9,it;q=0.8' \
  --cookie $cookie_jar \
  --data-raw "{'dynamicLoad':true,'plugins':['cloudbees-folder','antisamy-markup-formatter','build-timeout','credentials-binding','timestamper','ws-cleanup','ant','gradle','workflow-aggregator','github-branch-source','pipeline-github-lib','pipeline-stage-view','git','ssh-slaves','matrix-auth','pam-auth','ldap','email-ext','mailer'],'Jenkins-Crumb':'$only_crumb'}"




=====================================================================
# Docker
------
#Uninstall old versions first
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine \
                  podman \
                  runc
sudo yum remove docker*
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
yum list docker-ce --showduplicates | sort -r
#docker-ce-3:24.0.0-1.el8 (docker-ce-<VERSION_STRING>)
#sudo yum install docker-ce-<VERSION_STRING> docker-ce-cli-<VERSION_STRING> containerd.io docker-buildx-plugin docker-compose-plugin
sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl start docker
mkdir /u01/docker 
rsync -avxP /var/lib/docker/  /u01/docker  
sudo nano /lib/systemd/system/docker.service 
#Find the following line:  ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock & Replace this (--data-root /u01/docker) using below command
#sed -i '13s|existingword|existingword newword|' /lib/systemd/system/docker.service
sed -i '13s|/usr/bin/dockerd|/usr/bin/dockerd --data-root /u01/docker|' /lib/systemd/system/docker.service
sudo systemctl daemon-reload
systemctl restart docker

#Docker compose installation
sudo curl -L "https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-$(uname -s)-$(uname -m)"  -o /usr/local/bin/docker-compose
sudo mv /usr/local/bin/docker-compose /usr/bin/docker-compose
sudo chmod +x /usr/bin/docker-compose
#sudo yum install docker-compose-plugin
docker-compose --version

nexus
------
#! /bin/bash
yum install java-1.8.0-openjdk.x86_64 -y
mkdir /app && cd /app
wget -O nexus.tar.gz https://download.sonatype.com/nexus/3/latest-unix.tar.gz
tar -zxvf nexus.tar.gz
mv nexus-3* nexus
sudo adduser nexus
sudo chown -R nexus:nexus /app/nexus
sudo chown -R nexus:nexus /app/sonatype-work
echo 'run_as_user = "nexus"' | cat > nexus/bin/nexus.rc

sudo tee /etc/systemd/system/nexus.service <<EOF
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=nexus
Group=nexus
ExecStart=/app/nexus/bin/nexus start
ExecStop=/app/nexus/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

sudo chkconfig nexus on
systemctl start nexus
systemctl status nexus
cat /app/sonatype-work/nexus3/admin.password
====================================================================================
MYSQL
====================================================================================
sudo yum remove mysql* -y
sudo yum remove mysql-community-server -y
sudo yum remove mysql-client mysql-server -y
sudo rm -rf /etc/mysql 
sudo rm -rf /var/lib/mysql  
sudo rm -rf /var/log/mysqld.log 

sudo yum install -y wget
sudo wget https://dev.mysql.com/get/mysql80-community-release-el8-4.noarch.rpm
sudo yum install mysql80-community-release-el8-4.noarch.rpm -y
sudo yum-config-manager --disable mysql57-community
sudo yum-config-manager --enable mysql80-community
sudo yum repolist enabled | grep mysql
sudo yum module disable mysql
sudo yum install mysql-community-server -y
sudo systemctl start mysqld
sudo systemctl status mysqld
cat /var/log/mysqld.log | grep "temporary password"

=====================================
ALTER USER 'root'@'localhost' IDENTIFIED BY 'DB@tesT2#';
CREATE USER 'flywayUser'@'%' IDENTIFIED WITH mysql_native_password BY 'DB@tesT21#';
GRANT ALL PRIVILEGES ON *.* TO 'flywayUser'@'%' WITH GRANT OPTION;
GRANT REPLICATION SLAVE ON *.* TO 'flywayUser'@'%';
GRANT RELOAD, LOCK TABLES, PROCESS, REPLICATION CLIENT ON *.* TO 'flywayUser'@'%';


===================================================
it is not working ERROR: mysql passwd not working 
sudo mkdir /u01
sudo chown -R mysql:mysql /u01
sudo systemctl status mysqld
sudo systemctl stop mysqld
sudo systemctl status mysqld
cd /var/lib/mysql
ls -lrt
sudo rsync -av /var/lib/mysql /u01
sudo mv /var/lib/mysql /var/lib/mysql-$(date "+%Y%m%d_%H%M%S").bak
sudo cp -r /etc/my.cnf /etc/my.cnf.bkp
sed -i '27s|datadir=/var/lib/mysql|datadir=/u01/docker/mysql|' /etc/my.cnf
sed -i '28s|socket=/var/lib/mysql/mysql.sock|socket=/u01/mysql/mysql.sock|' /etc/my.cnf
echo -e "[client]\nport=3306\nsocket=/u01/mysql/mysql.sock" >> /etc/my.cnf
sudo setenforce 0 #tempory
suo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
sudo systemctl start mysqld
sudo systemctl status mysqld

