#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
RELEASE_PATH=$1
if [ -z $RELEASE_PATH ]; then 
	RELEASE_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd ../../ && pwd ); 
fi

cd ${RELEASE_PATH}
echo
echo "-------------------------------------------------"
echo "- Easycom Solutions - Install Apache for travis -"
echo "-------------------------------------------------"
echo
if [[ $PHPUNIT_COVERAGE_ENABLE = 1 ]]; then

	#
	# We add some files before and after execution script to handle coverage analysis
	#
	echo "-> configuration de la trace xdebug"
	# This configuration is appended to .user.ini; which is used by php-fpm
	sudo cp ${DIR}/.user.ini ${RELEASE_PATH}/htdocs/.user.ini
	sudo sed -i "s?%RELEASE_PATH%?${RELEASE_PATH}?g" ./htdocs/.user.ini
	
	#
	# We add the phpunit_coverage files at the webroot, and make some change to it because we just want to trace coverage of our module
	#
	cp ${RELEASE_PATH}/develop/vendor/phpunit/phpunit-selenium/PHPUnit/Extensions/SeleniumCommon/phpunit_coverage.php ${RELEASE_PATH}/htdocs/
	sudo sed -i "s?realpath(__DIR__)?'${RELEASE_PATH}/develop'?g" ${RELEASE_PATH}/htdocs/phpunit_coverage.php
fi

#
# Install apache for php-fpm
#
echo "-> Apt-get update & install of apache with mod fastcgi"
sudo apt-get update
sudo apt-get install apache2 libapache2-mod-fastcgi -y


#
# Create SSL certificate for apache
#
echo "-> Create the key file for ssl certificate"
sudo openssl genrsa -out /etc/ssl/private/localhost.key 2048
echo "-> Create the certificate with 10 years expiration time"
sudo openssl req -new -x509 -key /etc/ssl/private/localhost.key -out /etc/ssl/certs/localhost.crt -days 3650 -subj /CN=localhost
sudo openssl x509 -in /etc/ssl/certs/localhost.crt -out /etc/ssl/certs/localhost.pem
sudo openssl rsa -in /etc/ssl/private/localhost.key >> /etc/ssl/certs/localhost.pem

#
# Configure PHP-FPM
#
echo "-> Copy of PHP-FPM conf for the specific PHP version"
sudo cp ~/.phpenv/versions/$(phpenv version-name)/etc/php-fpm.conf.default ~/.phpenv/versions/$(phpenv version-name)/etc/php-fpm.conf

echo "-> Config of PHP-FPM and start process"
echo "cgi.fix_pathinfo = 1" >> ~/.phpenv/versions/$(phpenv version-name)/etc/php.ini
~/.phpenv/versions/$(phpenv version-name)/sbin/php-fpm

#
# Configure Apache
#
echo "-> Enable apaches modules : rewrite actions fastcgi alias deflate headers"
sudo a2enmod rewrite actions fastcgi alias deflate headers ssl

echo "-> Configure apache vhost"
sudo cp ${DIR}/default.vhost /etc/apache2/sites-available/default
sudo sed -i "s?%TRAVIS_BUILD_DIR%?$(pwd)?g" /etc/apache2/sites-available/default
sudo service apache2 restart


exit 0;