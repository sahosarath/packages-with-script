JENKINS installation with specific path
--------------------------------------------
## Ubuntu ###
#!/bin/bash

# Set variables
jenkins_version="2.375.2"
jenkins_home="/u01/jenkins"

# Ensure Jenkins user and group exist
sudo adduser --system --group --home "$jenkins_home" jenkins

# Stop Jenkins service
sudo systemctl stop jenkins || true  # Ignore errors if Jenkins is not running

# Install Java (if not already installed)
sudo apt install -y default-jdk

# Install net-tools (required dependency for Jenkins)
sudo apt install -y net-tools

# Download Jenkins package (DEB format)
wget -O "/tmp/jenkins_${jenkins_version}_all.deb" "https://pkg.jenkins.io/debian-stable/binary/jenkins_${jenkins_version}_all.deb"

# Install Jenkins
sudo dpkg -i "/tmp/jenkins_${jenkins_version}_all.deb"

# Create Jenkins service drop-in directory
sudo mkdir -p /etc/systemd/system/jenkins.service.d/

# Create a systemd drop-in configuration file
sudo tee /etc/systemd/system/jenkins.service.d/jenkins.conf > /dev/null << EOF
[Service]
Environment="JENKINS_HOME=${jenkins_home}"
EOF

# Start Jenkins service
sudo systemctl start jenkins

# Enable Jenkins service on boot
sudo systemctl enable jenkins

# Ensure Jenkins home directory exists and is owned by the Jenkins user
sudo mkdir -p "$jenkins_home"
sudo chown -R jenkins:jenkins "$jenkins_home"

# Restart Jenkins service
sudo systemctl restart jenkins
----------------------------------------------------------------------------------------
## Linux ###
#!/bin/bash

# Set variables
jenkins_version="2.375.2"
jenkins_home="/u01/jenkins"

#sudo mkdir -p /u01/jenkins

#sudo chown -R jenkins:jenkins /u01/jenkins

# Stop Jenkins service
sudo systemctl stop jenkins || true  # Ignore errors if Jenkins is not running

# Remove Jenkins packages
sudo yum remove -y jenkins

# Remove Jenkins data directory
sudo rm -rf "$jenkins_home"

# Install Java (if not already installed)
sudo yum install -y java-11-openjdk

# Download Jenkins package
wget -O "/tmp/jenkins-${jenkins_version}.rpm" "https://pkg.jenkins.io/redhat-stable/jenkins-${jenkins_version}-1.1.noarch.rpm"

# Install Jenkins
sudo yum install -y "/tmp/jenkins-${jenkins_version}.rpm"

# Create Jenkins service drop-in directory
sudo mkdir -p /etc/systemd/system/jenkins.service.d/

# Create a systemd drop-in configuration file
sudo tee /etc/systemd/system/jenkins.service.d/jenkins.conf > /dev/null << EOF
[Service]
Environment="JENKINS_HOME=${jenkins_home}"
EOF

# Start Jenkins service
sudo systemctl start jenkins

# Enable Jenkins service on boot
sudo systemctl enable jenkins

sudo mkdir -p /u01/jenkins

sudo chown -R jenkins:jenkins /u01/jenkins

# reStart Jenkins service
sudo systemctl restart jenkins

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
sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
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
#sudo apt install openjdk-8-jdk #Ubuntu
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
###OCI Linux Server #############

#!/bin/bash

NEXUS_VERSION="3.24.0-02"  # Specify the desired Nexus version

# Install Java
yum install java-1.8.0-openjdk.x86_64 -y

# Create Nexus user and directories
mkdir /app && cd /app
wget -O nexus.tar.gz "https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz"
tar -zxvf nexus.tar.gz
mv nexus-3* nexus
sudo adduser nexus
sudo chown -R nexus:nexus /app/nexus
sudo chown -R nexus:nexus /app/sonatype-work
echo 'run_as_user="nexus"' > nexus/bin/nexus.rc

# Create systemd service file
sudo tee /etc/systemd/system/nexus.service <<EOF
[Unit]
Description=Nexus service
After=network.target

[Service]
Type=simple
LimitNOFILE=65536
User=nexus
Group=nexus
ExecStart=/app/nexus/bin/nexus start
ExecStop=/app/nexus/bin/nexus stop
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

# Adjust SELinux context for the Nexus executable
chcon -R system_u:object_r:bin_t:s0 /app/nexus/bin/nexus

# Enable and start the Nexus service
sudo systemctl enable nexus
sudo systemctl start nexus
sudo systemctl status nexus

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
yum clean packages
#sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql
yum update -y
#sudo yum install mysql-community-server mysql-community-client mysql-community-common mysql-community-libs mysql-community-icu-data-files -y
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
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
sudo systemctl start mysqld
sudo systemctl status mysqld

