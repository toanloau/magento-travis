#!/bin/bash

#
# Install and configure Xvfb to have a screen of 1650*1080
#
sudo apt-get install -y xvfb
Xvfb :99 -screen 0 1650x1080x24 > /tmp/xvfb.log 2>&1 &

#
# Download selenium server and install it as a service
#
sudo mkdir /usr/lib/selenium
cd /tmp
if [ ! -f selenium-server-standalone-*.jar ]; then
	echo "-> Download selenium server v2.45.0"
	wget http://selenium-release.storage.googleapis.com/2.45/selenium-server-standalone-2.45.0.jar
fi 
echo "-> Copy selenium server to /usr/lib/selenium/selenium-server-standalone.jar"
sudo cp selenium-server-standalone-*.jar /usr/lib/selenium/selenium-server-standalone.jar

echo "-> Create log directory for selenium server"
sudo mkdir -p /var/log/selenium
sudo chmod a+w /var/log/selenium

file=$(cat <<EOF
#!/bin/bash
### BEGIN INIT INFO
# Provides:          selenium
# Required-Start:    \$remote_fs \$syslog
# Required-Stop:     \$remote_fs \$syslog
# Should-Start:      \$network \$named \$time
# Should-Stop:       \$network \$named \$time
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# X-Interactive:     true
# Short-Description: Start selenium server
### END INIT INFO

SELENIUM_DIR="/usr/lib/selenium"
SELENIUM_SERVER="\$SELENIUM_DIR/selenium-server-standalone.jar"
SELENIUM_OPTIONS="-port 4444 -trustAllSSLCertificates"
LOG_FILE="/var/log/selenium/output.log"
LOG_ERROR="/var/log/selenium/error.log"

case \$1 in
    start)
        if test -f /tmp/selenium.pid
        then
            echo "Selenium is already running."
        else
            export DISPLAY=localhost:99.0
            java -jar \$SELENIUM_SERVER \$SELENIUM_OPTIONS > \$LOG_FILE 2> \$LOG_ERROR & echo \$! > /tmp/selenium.pid
            echo "Starting Selenium..."
            sleep 10
            error=\$?
            if test \$error -gt 0
            then
                echo "\${bon}Error \$error! Couldn't start Selenium!\${boff}"
            fi
        fi
    ;;
    stop)
        if test -f /tmp/selenium.pid
        then
            echo "Stopping Selenium..."
            PID=\$(cat /tmp/selenium.pid)
            kill -3 \$PID
            if kill -9 \$PID ;
                then
                    sleep 2
                    test -f /tmp/selenium.pid && rm -f /tmp/selenium.pid
                else
                    echo "Selenium could not be stopped..."
                fi
        else
            echo "Selenium is not running."
        fi
        ;;
    restart)
        if test -f /tmp/selenium.pid
        then
            kill -HUP \$(cat /tmp/selenium.pid)
            test -f /tmp/selenium.pid && rm -f /tmp/selenium.pid
            sleep 1
            export DISPLAY=localhost:99.0
            java -jar \$SELENIUM_SERVER \$SELENIUM_OPTIONS > \$LOG_FILE 2> \$LOG_ERROR & echo \$! > /tmp/selenium.pid
            sleep 10
            echo "Reload Selenium..."
        else
            echo "Selenium isn't running..."
        fi
        ;;
    *)      # no parameter specified
        echo "Usage: \$SELF start|stop|restart"
        exit 1
    ;;
esac
EOF
)
sudo echo "$file" > ./selenium

echo "-> Create selenium service in /etc/init.d"
sudo cp ./selenium /etc/init.d/
sudo chmod 755 /etc/init.d/selenium

echo "-> Add selenium server to start at startup"
sudo update-rc.d selenium defaults

echo "-> Launch selenium server"
sudo service selenium start

exit 0;