#!/bin/bash
LOG=/tmp/sonar.log
MYSQL_URL=http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
MYSQL_RPM=$(echo $MYSQL_URL | cut -d / -f 4)
SONAR_URL=https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-6.7.6.zip
SONAR_ZIP=$(echo $SONAR_URL | awk -F / '{print $NF}')
SONAR_SRC=$(echo $SONAR_ZIP | sed 's/.zip//')

R='\033[0;31m'
G='\033[0;32m'
Y='\033[0;33m'
N='\033[0;37m'

fun(){
    if [ $1 -eq 0 ] ; then
	  echo -e "$2 ...... $G success $N"
	 else
	  echo -e "$2 ......$R failed $N"
	   exit 1
	fi
}

yum install wget unzip java-1.8.0-openjdk -y &>>$LOG
fun $? "Installing sonarqube dependencies"

wget $MYSQL_URL -O $MYSQL_RPM &>>$LOG
fun $? "Download MYSQL"

rpm -ivh $MYSQL_RPM &>>$LOG
yum install mysql-server -y &>>$LOG
fun $? "Installing MYSQL package"

systemctl start mysqld
fun $? "starting MYSQL service"

if [ -f /tmp/sonar.sql ]; then
  echo -e "$Y sonarqube database updated $N"
else
  echo "CREATE DATABASE sonarqube_db;
  CREATE USER 'sonarqube_user'@'localhost' IDENTIFIED BY 'password';
  GRANT ALL PRIVILEGES ON sonarqube_db.* TO 'sonarqube_user'@'localhost' IDENTIFIED BY 'password';
  FLUSH PRIVILEGES; " > /tmp/sonar.sql
  mysql < /tmp/sonar.sql
fi 

echo -e "$Y Creating sonarqube database Account $N"
useradd sonarqube &>>$LOG


if [ -f /tmp/$SONAR_ZIP ]; then
  echo "sonarqube package installation is done"
else
  wget $SONAR_URL -O /tmp/$SONAR_ZIP &>>$LOG
  cd /tmp/
  unzip $SONAR_ZIP &>>$LOG
  mv /tmp/$SONAR_SRC /opt/sonarqube
  chown sonarqube. /opt/sonarqube -R
  
  echo "sonar.jdbc.username=sonarqube_user
      sonar.jdbc.password=password
  sonar.jdbc.url=jdbc:mysql://localhost:3306/sonarqube_db?useUnicode=true&amp;characterEncoding=utf8&amp;rewriteBatchedStatements=true&amp;useConfigs=maxPerformance"  >>/opt/sonarqube/conf/sonar.properties

fi

echo "Updating sonarqube sonar.sh file"
sed -i 's/#RUN_AS_USER=/RUN_AS_USER=sonarqube/g'  /opt/sonarqube/bin/linux-x86-64/sonar.sh

sh /opt/sonarqube/bin/linux-x86-64/sonar.sh start