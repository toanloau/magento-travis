# travis-scripts
This respository purpose is to be used as a submodule of others projects to help for travis use in FTDD approach.

Sample of expected strucure of the repository for a magento module :
```
	├── develop > everything required to develop or contribute the module
	│	└── conf
	│	└── travis (this repo as submodule)
	│	└── vagrant (https://github.com/Easycom-Solutions/vagrant-box.git as submodule)
	│	└── composer.json > require-dev composer file
	│	└── Vagrantfile
	├── htdocs > sources of the module
	├── .gitignore
	├── .gitmodules
	├── .travis.yml
	├── .scrutinizer.yml
	├── composer.json > file to publish the module on packgist
	├── modman > mapping of files for magento module
	└── phpunit.xml > PhpUnit configuration

```

Example quick startup for a new Magento module
```bash
mkdir -p my-module/develop my-module/htdocs
cd my-module
git init
git submodule add https://github.com/Easycom-Solutions/travis-scripts.git develop/travis
git submodule add https://github.com/Easycom-Solutions/vagrant-box.git develop/vagrant
cp develop/travis/.travis.yml.sample .travis.yml
cp develop/travis/phpunit.xml.sample phpunit.xml
cd develop
echo -e "{\n    \"config\":\n    {\n        \"bin-dir\": \"../bin\"\n    }\n}" > composer.json
composer require phpunit/phpunit
composer require phpunit/phpunit-selenium
```

## install-composer.sh
By default, the 'composer install' command may fail from travis because Github limit the number of request per day; and many developpers are using travis so the limit is reached quickly 
This script will use your secured token GITHUB_COMPOSER_AUTH to get composer projects from github; this avoid issue on travis.
And if you want to test on PHP 5.2, the script change the version of PHP for composer because phars files were created in version 5.3; so composer won't work.
Don't forget to add you secure token to your .travis.yml file

### Create the token
On your Github account, go to 
* Settings > Applications > Personal access token > Generate new Token
* Set a name (like 'Travis'), uncheck all checkboxes
* Click on 'Generate token'

Save the generated token in a safe place, then add it to your .travis.yml file

### Add token to travis config
Once .travis.yml file is public, travis let you encrypt somes custom env vars to be unique and link to your github project, so these secured vars won't be usable on other projects.
```bash
gem install travis
travis encrypt GITHUB_COMPOSER_AUTH {your_token}
```
add the line "secure: ..." to global:env: section of your .travis.yml file
```yaml
global:
  env:
    - secure: "..."
```

### How to use
The script takes one argument : the path to your composer.json file
```bash
bash install-composer.sh /path/to/composer.json/
```

## install-apache.sh
This script will install apache on travis vm (by default travis just use PHP).
The following modules are enable : 
* rewrite 
* actions 
* fastcgi 
* alias 
* deflate 
* headers 
* ssl (with selfsigned certificate)

If the env var PHPUNIT_COVERAGE_ENABLE is defined to 1, then .user.ini file will be added to htdocs folder.
This will enable code coverage for selenium testing (FTDD); don't forget to add "phpunit/phpunit-selenium" to your composer file

### How to use
The script takes one argument : the path to your project root
```bash
bash install-apache.sh $TRAVIS_BUILD_DIR
```

## install-magento.sh
This script help to install magento via magerun.

### How to use
The script take some arguments :
* --release-path : Path to project root (must contain an 'htdocs' folder)
* --magento-version : See Magerun to get possible versions, default value => "magento-ce-1.9.1.0"
* --magento-baseurl : To set a custom baseurl, default value => localhost
* --magento-sample-data : Define if you want to install sample data, default value => no
* --magento-db-host : Default value => 127.0.0.1
* --magento-db-port : Default value => 3306
* --magento-db-dbname : Default value => localdb
* --magento-db-dbuser : Default value => root
* --magento-db-dbpass : Default value => vagrant

Travis use '' as root password for mysql, you have to change that to get the script working; else you'll get an error because you try to use a password with mysql.

Add this line to your .travis.yml :
```yaml
install: 
  - echo "USE mysql;\nUPDATE user SET password=PASSWORD('password') WHERE user='root';\nFLUSH PRIVILEGES;\n" | mysql -u root
  - bash install-magento.sh --release-path=$TRAVIS_BUILD_DIR --magento-db-dbpass='password'
```

## install-selenium-server.sh
This script will install xvfb (virtual screen) and selenium server to allow execution of PHPUnit Selenium Tests.

```bash
bash install-selenium-server.sh
```



