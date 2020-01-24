#!/bin/bash

#
# Copyright 2020 ForgeRock AS
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# AM configuration variables
# export AM_HOST="am.mytestrun.com"
# export AM_PASSWORD="F0rgeR0ck2020"
export AM_URL="http://${AM_HOST}:8080"
export AM_HOME="/root/am"
export AMSTER_HOME="/opt/forgerock/amster"

# Environment variables
export TOMCAT_HOME="/usr/local/tomcat"
export JAVA_HOME="/usr/lib/jvm/default-jvm/jre"
export WORK_DIR="/root/forgerock"

# Config page. This comes up if AM is not configured
export CONFIG_URL="http://localhost:8080/config/options.htm"

# Wait for OpenAM to come up before configuring it
wait_for_am()
{
   response="000"

	while true
	do
		echo "Waiting for OpenAM server at ${CONFIG_URL} "

		curl ${CONFIG_URL}


		response=$(curl --write-out %{http_code} --silent --connect-timeout 15 --output /dev/null ${CONFIG_URL} )

      echo "Got Response code $response"
      if [ ${response} = "302" ]; then
         echo "Checking to see if OpenAM is already configured. Will not reconfigure"

         curl ${CONFIG_URL} | grep -q "Configuration"
         if [ $? -eq 0  ]; then
            break
         fi
         echo "It looks like OpenAM is configured already. Exiting"

         exit 0
      fi
      if [ ${response} = "200" ];
      then
         echo "OpenAM web app is up and ready to be configured"
         break
      fi

      echo "response code ${response}. Will continue to wait"
      sleep 5
   done

	# Sleep additional time in case DJ is not quite up yet
	echo "About to begin configuration in 10 seconds"
	sleep 10
}

#
# Start tomcat and wait until startup is complete
#
function start_tomcat() {
    # Clean the logs so we don't read the previous startup message
	rm -f ${TOMCAT_HOME}/logs/catalina.out

    # Start tomcat
    ${TOMCAT_HOME}/bin/catalina.sh start

    # Wait for tomcat to complete startup
    count=30
    printf "\nWaiting for server startup"
    while [[ -z "$(cat ${TOMCAT_HOME}/logs/catalina.out | grep "Server startup")" && count -gt 0 ]]; do
        sleep 2 && printf "."
        ((count--))
    done

    # If tomcat does not start in 1 minute then kill the process and cat the log
    if [[ count -eq 0 ]]; then
        printf "\nServer failed to startup normally. Tomcat log:\n\n"
        cat ${TOMCAT_HOME}/logs/catalina.out
        pkill -9 -f tomcat
    else
        printf "\nServer started\n"
    fi
}

#
# Stop tomcat and wait until shutdown is complete
#
function stop_tomcat() {
    # Stop tomcat
    ${TOMCAT_HOME}/bin/catalina.sh stop

    # Wait for tomcat to complete shutdown
    count=30
    printf "\nWaiting for server shutdown"
    while [[ -z "$(cat ${TOMCAT_HOME}/logs/catalina.out | grep "Destroying ProtocolHandler")" && count -gt 0 ]]; do
        sleep 2 && printf "."
        ((count--))
    done

    # If tomcat does not stop in 1 minute then kill the process and cat the log
    if [[ count == 0 ]]; then
        echo "Server failed to shutdown normally. Tomcat log:\n\n"
        cat ${TOMCAT_HOME}/logs/catalina.out
        pkill -9 -f tomcat
    else
        printf "\nServer stopped\n"
    fi
}

#
# Restart tomcat
#
function restart_tomcat() {
    stop_tomcat
    sleep 5
    start_tomcat
}

#
# Start tomcat and install AM with Amster
#
function install_am() {
    start_tomcat

    echo "Installing AM"
    cd ${AMSTER_HOME}
    ./amster install-am.amster -d -D AM_URL=${AM_URL} -D AM_PASSWORD=${AM_PASSWORD} -D AM_HOME=${AM_HOME}
    # Execute and notify the caller if this fails.
    if [[ $? -ne 0 ]]; then
        echo "Amster Installation failed"
        exit 1
    fi
    # fix amster private key login (https://bugster.forgerock.org/jira/browse/OPENAM-11134)
    sed -e "s/from=\"127.0.0.0\/24,::1\" //g" -i ${AM_HOME}/amster_rsa.pub
    sed -e "s/from=\"127.0.0.0\/24,::1\" //g" -i ${AM_HOME}/authorized_keys

    cd - &>/dev/null
}

#
# Use Amster to import AM configuration
#
function configure_am() {
    echo "Configuring AM"
    cd ${AMSTER_HOME}
    ./amster import-config.amster \
        -D AM_URL=${AM_URL} \
        -D AM_HOST=${AM_HOST} \
        -D AMSTER_KEY=${AM_HOME}/amster_rsa \
        -D AM_CONFIG_PATH=/opt/forgerock/am/configuration
    cd - &>/dev/null
}

#
# Use Amster to export AM configuration
#
function snapshot_am() {
    echo "Snapshotting AM"
    cd ${AMSTER_HOME}
    ./amster export-config.amster \
        -D AM_URL=${AM_URL} \
        -D AM_HOST=${AM_HOST} \
        -D AMSTER_KEY=${AM_HOME}/amster_rsa \
        -D AM_CONFIG_PATH=/opt/forgerock/am/snapshot/`date '+%Y%m%d%H%M%S'`
    cd - &>/dev/null
}

#
# Quick install will bring the cloud environment to the state
# it would be in after the installation guide has been completed
#
function quick_install() {
    start_tomcat
    configure_am
    restart_tomcat
}
