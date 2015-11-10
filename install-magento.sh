#!/bin/bash

MAGE_LATEST="magento-ce-1.9.1.0"

# ========================================================================
# -> Get arguments values
# ------------------------------------------------------------------------
for i in "$@"
do
	key="$i"
	case $key in
		
		--release-path=*)
			RELEASE_PATH="${i#*=}"
			shift;;
		--magento-version=*)
			MAGENTO_VERSION="${i#*=}"
			shift;;
   		--magento-baseurl=*)
			MAGENTO_BASEURL="${i#*=}"
			shift;;
		--magento-sample-data=*)
			MAGENTO_SAMPLE_DATA="${i#*=}"
			shift;;
		--magento-db-host=*)
			MAGENTO_DB_HOST="${i#*=}"
			shift;;
		--magento-db-port=*)
			MAGENTO_DB_PORT="${i#*=}"
			shift;;
		--magento-db-dbname=*)
			MAGENTO_DB_NAME="${i#*=}"
			shift;;
		--magento-db-dbuser=*)
			MAGENTO_DB_USER="${i#*=}"
			shift;;
		--magento-db-dbpass=*)
			MAGENTO_DB_PASS="${i#*=}"
			shift;;
    	*)
    	 echo "$1 unknown argument" ;;
	esac 
done

# ========================================================================
# -> Define default values
# ------------------------------------------------------------------------
if [[ -d /vagrant ]]; then
	cd /vagrant/develop
	if [ -z $RELEASE_PATH ]; then RELEASE_PATH='/vagrant'; fi
else
	if [ -z $RELEASE_PATH ]; then RELEASE_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd ../../ && pwd ); fi		
fi
if [ -z $INSTALL_APACHE_FOR_TRAVIS ]; then INSTALL_APACHE_FOR_TRAVIS=false; fi
if [ -z $MAGENTO_VERSION ]; then MAGENTO_VERSION=$MAGE_LATEST; fi
if [ -z $MAGENTO_BASEURL ]; then MAGENTO_BASEURL="www.magento.local"; fi
if [ -z $MAGENTO_SAMPLE_DATA ]; then MAGENTO_SAMPLE_DATA=no; fi
if [ -z $MAGENTO_DB_HOST ]; then MAGENTO_DB_HOST="127.0.0.1"; fi
if [ -z $MAGENTO_DB_PORT ]; then MAGENTO_DB_PORT="3306"; fi
if [ -z $MAGENTO_DB_NAME ]; then MAGENTO_DB_NAME="localdb"; fi
if [ -z $MAGENTO_DB_USER ]; then MAGENTO_DB_USER="root"; fi
if [ -z $MAGENTO_DB_PASS ]; then MAGENTO_DB_PASS="vagrant"; fi

# ========================================================================
# -> Start script
# ------------------------------------------------------------------------

echo
echo "-------------------------------------------------"
echo "- Easycom Solutions - Install Magento FTDD env  -"
echo "-------------------------------------------------"
echo
echo "Installing ${MAGENTO_VERSION} in ${RELEASE_PATH}/htdocs"
echo "using Database Credentials:"
echo "    Host: ${MAGENTO_DB_HOST}"
echo "    Port: ${MAGENTO_DB_PORT}"
echo "    User: ${MAGENTO_DB_USER}"
echo "    Pass: [hidden]"
echo "    DB: ${MAGENTO_DB_NAME}"
echo

#
# Install Magerun
#
echo "-> Install N98-Magerun"
if [[ ! -f /usr/local/bin/magerun ]]; then
	curl -o n98-magerun.phar https://raw.githubusercontent.com/netz98/n98-magerun/master/n98-magerun.phar
	chmod +x ./n98-magerun.phar
	sudo cp ./n98-magerun.phar /usr/local/bin/magerun
	sudo rm ./n98-magerun.phar
else
	sudo magerun self-update
fi

#
# Move sources of the module in tmp
#
echo "-> Move sources of the module in tmp"
cd ${RELEASE_PATH}
TMP_DIR="/tmp/_tmp-$(date +%s)"
mkdir ${TMP_DIR}

rsync -a --exclude-from=.gitignore ./ ${TMP_DIR}/
rm -Rf ${RELEASE_PATH}/htdocs/*
find ${RELEASE_PATH}/htdocs/ -type f -delete

#
# Create db for magento if not exist
#
mysql -h ${MAGENTO_DB_HOST} -P ${MAGENTO_DB_PORT} -u ${MAGENTO_DB_USER} -p${MAGENTO_DB_PASS} -e "DROP DATABASE IF EXISTS ${MAGENTO_DB_NAME}; CREATE DATABASE ${MAGENTO_DB_NAME} CHARACTER SET utf8;"

#
# Install Magento in htdocs folder
#
echo "-> Install Magento in htdocs folder with default params (admin/password123)"
magerun install \
	--dbHost="${MAGENTO_DB_HOST}" \
	--dbUser="${MAGENTO_DB_USER}" \
	--dbPass="${MAGENTO_DB_PASS}" \
	--dbName="${MAGENTO_DB_NAME}" \
	--installSampleData=${MAGENTO_SAMPLE_DATA} \
	--useDefaultConfigParams=yes \
	--magentoVersionByName="${MAGENTO_VERSION}" \
	--installationFolder="${RELEASE_PATH}/htdocs/" \
	--baseUrl="http://${MAGENTO_BASEURL}/"

echo '-> Disable admin notifications'
magerun admin:notifications

echo '-> Use HTTPS in frontend'
magerun config:set 'web/secure/use_in_frontend' '1'

echo '-> Use en_US as locale'
magerun config:set 'general/locale/code' 'en_US'

echo '-> Enable cache'
magerun cache:enable

#
# Install the module in Magento (copy back to the original place)
#
echo "-> Install the module in Magento (copy back to the original place)"
rsync -a ${TMP_DIR}/htdocs/* ${RELEASE_PATH}/htdocs/
rm -Rf ${TMP_DIR}

echo "-> Delete magento cache files"
rm -Rf ${RELEASE_PATH}/htdocs/var/cache


exit 0