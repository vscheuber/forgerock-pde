#
# Copyright (c) 2016-2020 ForgeRock AS.
#

FROM tomcat:8.5-alpine
ARG AM_HOST=${AM_HOST}
ARG AM_PASSWORD=${AM_PASSWORD}

# Add OS tools we need
RUN apk add curl

# Remove tomcat manager, samples, and doc
RUN rm -r /usr/local/tomcat/webapps/*

# Apply tomcat configuration files
ADD build/tomcat-config /usr/local/tomcat/conf

# Add AM resources
ADD build/resources/am.war /usr/local/tomcat/webapps/ROOT.war
ADD build/resources/amster.zip /tmp/amster.zip
RUN mkdir -p /opt/forgerock/amster && unzip -q /tmp/amster.zip -d /opt/forgerock/amster
ADD build/amster/install-am.amster /opt/forgerock/amster/install-am.amster
ADD build/amster/import-config.amster /opt/forgerock/amster/import-config.amster
ADD build/amster/export-config.amster /opt/forgerock/amster/export-config.amster
ADD build/commands.sh /opt/forgerock/am/commands.sh
RUN chmod a+x /opt/forgerock/am/commands.sh
RUN /bin/bash -c "echo \"source /opt/forgerock/am/commands.sh\" >> /root/.bashrc" && echo "alias ll='ls -lah'" >> /root/.bashrc
ADD build/amster/am-config /opt/forgerock/am/configuration
ADD build/amster/am-snapshot /opt/forgerock/am/snapshot

# Install AM
RUN /bin/bash -c "source /opt/forgerock/am/commands.sh && install_am && configure_am && stop_tomcat"

CMD [ "catalina.sh", "run" ]