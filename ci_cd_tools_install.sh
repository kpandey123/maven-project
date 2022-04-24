#!/bin/bash
################################################################
# Author: Veera                                                #
# Position: DevOps Engineer                                    #
# Purpose: Installation Script for CI and CD                   #
################################################################
SONARQUBE=sonarqube
MYSQL_ROOT_PASSWORD=Devops@1234
MYSQL=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $11}')
NEXUS=nexus
#################################        JAVA / GIT / DOCKER / UTILS      #########################
sudo yum install java-1.8.0-openjdk* -y
sudo yum install  wget expect unzip git docker -y
echo 1 > /proc/sys/vm/drop_caches
echo 2 > /proc/sys/vm/drop_caches
################################           NEXUS         #########################
cd /opt
wget https://download.sonatype.com/nexus/3/latest-unix.tar.gz
tar -xvf latest-unix.tar.gz
mv nexus-3* nexus
cd /opt/nexus/bin
sudo useradd nexus
EXPECT_ELE=$(expect -c "
set timeout 10
spawn passwd nexus
expect \"New password:\"
send \"$NEXUS\r\"
#Retype new password:
expect \"Retype new password:\"
send \"$NEXUS\r\"
expect eof
")
cd /opt/nexus
chown -R nexus:nexus nexus/ sonatype-work/
cd /opt/nexus/bin
sed -i 's/2703/1024/g' nexus.vmoptions
echo '-Dstorage.diskCache.diskFreeSpaceLimit=1024' >>nexus.vmoptions
/opt/nexus/bin/nexus start
echo 1 > /proc/sys/vm/drop_caches
echo 2 > /proc/sys/vm/drop_caches
###################################        MAVEN    ############################
cd /opt/
wget https://mirrors.estointernet.in/apache/maven/maven-3/3.8.3/binaries/apache-maven-3.8.3-bin.tar.gz
tar -xvf apache-maven-3.8.3-bin.tar.gz
cd
echo 'export M2_HOME=/opt/apache-maven-3.8.3/' >>~/.bash_profile
echo
echo 'export M2=$M2_HOME/bin' >>~/.bash_profile
echo
echo 'export PATH=$M2:$PATH'  >>~/.bash_profile
echo
cd 
cd 
. .bash_profile
echo
################################               JENKINS           #####################################
wget https://rpmfind.net/linux/dag/redhat/el6/en/x86_64/dag/RPMS/daemonize-1.6.0-1.el6.rf.x86_64.rpm
yum install daemonize-1.6.0-1.el6.rf.x86_64.rpm
echo "Install Jenkins"
sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
sudo yum upgrade -y
sudo yum install jenkins java-11-openjdk-devel
sudo systemctl daemon-reload
sudo usermod -a -G docker jenkins
sudo service jenkins restart
sudo service docker restart
###########################                 TOMCAT                 ################################
cd /opt/
wget https://mirrors.estointernet.in/apache/tomcat/tomcat-8/v8.5.72/bin/apache-tomcat-8.5.72.tar.gz
tar -xvf apache-tomcat-8.5.72.tar.gz
cd /opt/apache-tomcat-8.5.72/conf
echo '<tomcat-users>' >tomcat-users.xml
echo '<user username="admin" password="admin" roles="manager-gui,admin-gui,manager-script"/>' >>tomcat-users.xml
echo '</tomcat-users>' >>tomcat-users.xml
cd /opt/apache-tomcat-8.5.72/webapps/manager/META-INF
sed -i '21,22d' context.xml
cd /opt/apache-tomcat-8.5.72/conf
sed -i 's/Connector port="8080"/Connector port="8087"/g' server.xml
/opt/apache-tomcat-8.5.72/bin/shutdown.sh
sleep 10
/opt/apache-tomcat-8.5.72/bin/startup.sh
echo 1 > /proc/sys/vm/drop_caches
echo 2 > /proc/sys/vm/drop_caches
############################               MYSQL                #############################
cd /opt/
wget https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
sudo yum install mysql57-community-release-el7-9.noarch.rpm -y
sudo yum install mysql-server
systemctl restart mysqld.service
sleep 10
MYSQL_ROOT_PASSWORD=Devops@12345
MYSQL=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $11}')
SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter password for user root:\"
send \"$MYSQL\r\"
expect \"New password:\"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"Re-enter new password:\"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"Change the password for root ?\ ((Press y\|Y for Yes, any other key for No) :\"
send \"y\r\"
send \"$MYSQL\r\"
expect \"New password:\"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"Re-enter new password:\"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"Do you wish to continue with the password provided?\(Press y\|Y for Yes, any other key for No) :\"
send \"y\r\"
expect \"Remove anonymous users?\(Press y\|Y for Yes, any other key for No) :\"
send \"y\r\"
expect \"Disallow root login remotely?\(Press y\|Y for Yes, any other key for No) :\"
send \"n\r\"
expect \"Remove test database and access to it?\(Press y\|Y for Yes, any other key for No) :\"
send \"y\r\"
expect \"Reload privilege tables now?\(Press y\|Y for Yes, any other key for No) :\"
send \"y\r\"
expect eof
")
echo $SECURE_MYSQL
########################################
SECURE_MYSQLSCHEMA=$(expect -c "
spawn  mysql -u root -p
expect \"Enter password:\"
send \"$MYSQL_ROOT_PASSWORD\r\"
expect \"mysql>\"
send \"CREATE DATABASE devops_db;\r\"
expect \"mysql>\"
send \"CREATE USER 'devops'@'localhost' IDENTIFIED BY 'Devops@1234';\r\"
expect \"mysql>\"
send \"GRANT ALL PRIVILEGES ON devops_db.* TO 'devops'@'localhost' IDENTIFIED BY 'Devops@1234';\r\"
expect \"mysql>\"
send \"FLUSH PRIVILEGES;\r\"
expect \"mysql>\"
send \"exit\r\"
expect eof
")
echo $SECURE_MYSQLSCHEMA
 #mysql -u root -p
 #SHOW DATABASES;
 #use devops_db;
 #SELECT user FROM mysql.user;
#########################################################################################
echo 1 > /proc/sys/vm/drop_caches
echo 2 > /proc/sys/vm/drop_caches
cd /opt/
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-6.4.zip
unzip sonarqube-6.4.zip
mv sonarqube-6.4 sonarqube
sudo useradd sonarqube
EXPECT_ELE=$(expect -c "
set timeout 10
spawn passwd sonarqube
expect \"New password:\"
send \"$SONARQUBE\r\"
#Retype new password:
expect \"Retype new password:\"
send \"$SONARQUBE\r\"
expect eof
")
chown -R sonarqube:sonarqube sonarqube/
cd /opt/sonarqube/conf
echo '-----------------' >>sonar.properties
echo 'sonar.jdbc.username=devops' >>sonar.properties
echo 'sonar.jdbc.password=Devops@1234' >>sonar.properties
echo 'sonar.jdbc.url=jdbc:mysql://localhost:3306/devops_db?useUnicode=true&characterEncoding=utf8&rewriteBatchedStatements=true&useConfigs=maxPerformance' >>sonar.properties
/opt/sonarqube/bin/linux-x86-64/sonar.sh start
echo 1 > /proc/sys/vm/drop_caches
echo 2 > /proc/sys/vm/drop_caches
cd 
. .bash_profile
##########################
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install ansible
#target/${POM_ARTIFACTID}-${POM_VERSION}.${POM_PACKAGING}
sudo chmod 666 /var/run/docker.sock
