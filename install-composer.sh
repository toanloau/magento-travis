#!/bin/bash
BASE_DIR=$1
cd ${BASE_DIR}
#
# Install require-dev composer packages
# If env = php 5.2 which is not supported by composer we temporaly force usage of php 5.3
#
echo "-> Update composer then install composer dependencies"
if [[ $TRAVIS_PHP_VERSION = '5.2' ]]; then
	phpenv global 5.3
fi

composer self-update

cd ${RELEASE_PATH}/develop
if [[ ! $GITHUB_COMPOSER_AUTH = '' ]]; then
	composer config -g github-oauth.github.com $GITHUB_COMPOSER_AUTH
fi

composer install

if [[ $TRAVIS_PHP_VERSION = '5.2' ]]; then
	phpenv global $TRAVIS_PHP_VERSION
fi