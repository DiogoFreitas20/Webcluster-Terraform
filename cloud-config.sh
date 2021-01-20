#!/bin/bash -x

# Reference: https://serverfault.com/questions/103501/how-can-i-fully-log-all-bash-scripts-actions
# Log everything
#
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/var/log/cloud-config-detail.log 2>&1

wget https://gist.githubusercontent.com/jdmedeiros/1add075e054c911776d26e97a84dfdec/raw/62c0ccd0e8d76e0dc9d1b15fe369d101dd7bc12f/logger.sh
source ./logger.sh

SCRIPTENTRY
DEBUG "Script starting."

sudo apt-get update && sudo apt-get -y upgrade
INFO "System updated and upgraded."

sudo apt-get -y install apache2 mysql-server php libapache2-mod-php php-mysql debconf-utils php-mbstring php-intl php-soap php-xml php-xmlrpc build-essential
INFO "Software packages installed."

cd /var/www
sudo git clone git://git.moodle.org/moodle.git
cd moodle
sudo git branch --track MOODLE_39_STABLE origin/MOODLE_39_STABLE
sudo git checkout MOODLE_39_STABLE
INFO "Moodle installed."

cd /var/www
sudo git clone https://github.com/joomla/joomla-cms.git
INFO "Joomla installed."

echo "<?php" >/tmp/info.php
echo "phpinfo();" >>/tmp/info.php
echo "?>" >>/tmp/info.php

sudo cp /tmp/info.php /var/www/joomla
sudo cp /tmp/info.php /var/www/moodle
rm /tmp/info.php
INFO "File info.php created at the Joomla and Moodle roots."

echo "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Passw0rd';" >/tmp/script.sql
echo "FLUSH PRIVILEGES;" >>/tmp/script.sql

sudo mysql </tmp/script.sql
rm /tmp/script.sql
INFO "MySQL root user updated with a password and mysql_native_password authentication."

echo "echo 'phpmyadmin phpmyadmin/dbconfig-install boolean true' | debconf-set-selections" >/tmp/script.sh
echo "echo 'phpmyadmin phpmyadmin/app-password-confirm password Passw0rd' | debconf-set-selections" >>/tmp/script.sh
echo "echo 'phpmyadmin phpmyadmin/mysql/admin-pass password Passw0rd' | debconf-set-selections" >>/tmp/script.sh
echo "echo 'phpmyadmin phpmyadmin/mysql/app-pass password Passw0rd' | debconf-set-selections" >>/tmp/script.sh
echo "echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections" >>/tmp/script.sh

sudo sh /tmp/script.sh
sudo apt-get -y install phpmyadmin
rm /tmp/script.sh
INFO "PHPMyAdmin installed."

sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/001-default.conf
sudo sed -i -e 's/:80/:8080/g' /etc/apache2/sites-available/001-default.conf
sudo sed -i -e 's/html/moodle/g' /etc/apache2/sites-available/001-default.conf
sudo sed -i -e 's/html/joomla-cms/g' /etc/apache2/sites-available/000-default.conf
sudo chown -R www-data:www-data /var/www/*
sudo a2ensite 001-default.conf
sudo sed -i -e 's/Listen 80/Listen 80\nListen 8080/g' /etc/apache2/ports.conf
sudo systemctl restart apache2
INFO "Web sited created. Joomla on port 80 and Moodle on port 8080."

DEBUG "Script reached the end."
SCRIPTEXIT

rm logger.sh
