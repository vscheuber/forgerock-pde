#
# Copyright (c) 2016-2020 ForgeRock AS.
#

FROM krallin/ubuntu-tini:bionic as download_tini
ARG IDM_HOST=${IDM_HOST}
ARG IDM_PASSWORD=${IDM_PASSWORD}

FROM adoptopenjdk/openjdk8:debian-slim as unpack
RUN apt-get update && apt-get install -y unzip && apt-get clean all
COPY build/resources/idm.zip /idm.zip
RUN mkdir -p /var/tmp/openidm && unzip -q /idm.zip -d /var/tmp && rm -fr /var/tmp/openidm/samples

FROM adoptopenjdk/openjdk8:debian-slim
ENV FORGEROCK_HOME /opt/forgerock

RUN apt-get update && apt-get install -y jq zip unzip curl bash wget dnsutils sysstat ldap-utils ttf-dejavu\
    && apt-get clean all \
    && addgroup --gid 11111 forgerock \
    && adduser --shell /bin/bash --home "$FORGEROCK_HOME" --uid 11111 --ingroup root  --disabled-password --gecos "" -q forgerock \
    && mkdir -p "$FORGEROCK_HOME" \
    && chown -R forgerock:root /opt \
    && chmod -R 0770 "${FORGEROCK_HOME}" \
    && find / -perm 6000 -type f -exec chmod a-s {} \; || true 

COPY --from=download_tini /usr/bin/tini /usr/bin/tini
COPY --from=download_tini /usr/bin/tini-static /usr/bin/tini-static

# Copy IDM files
COPY --from=unpack /var/tmp/openidm /opt/forgerock/idm/openidm
RUN chown -R forgerock:root /opt/forgerock/idm/openidm 

ADD build/commands.sh /opt/forgerock/idm/bin/commands.sh
ADD build/decrypt.jq /opt/forgerock/idm/bin/decrypt.jq
RUN chmod a+x /opt/forgerock/idm/bin/commands.sh
RUN /bin/bash -c "echo \"source /opt/forgerock/idm/bin/commands.sh\" >> /opt/forgerock/.bashrc" && echo "alias ll='ls -lah'" >> /opt/forgerock/.bashrc

# Override these to change the JVM:
ENV JAVA_OPTS -Xmx1024m -server -XX:+UseG1GC -XX:+IgnoreUnrecognizedVMOptions --add-opens=java.base/jdk.internal.loader=ALL-UNNAMED

COPY *.sh /opt/forgerock/idm/openidm/
COPY logging.properties /opt/forgerock/idm/project/pde/logging.properties

WORKDIR /opt/forgerock/idm/openidm

# Must be numeric. This is the forgerock user id.
USER 11111

ENV GIT_SSH_COMMAND ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /etc/git-secret/id_rsa


ENTRYPOINT ["/opt/forgerock/idm/openidm/docker-entrypoint.sh"]

CMD ["openidm"]
