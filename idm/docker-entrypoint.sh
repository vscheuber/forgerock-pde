#!/bin/bash
# Docker entry point for OpenIDM.
# set -x
source /opt/forgerock/idm/bin/commands.sh

PROJECT_HOME=/opt/forgerock/idm/project/pde
IDM_HOME=/opt/forgerock/idm/openidm
LOGGING_PROPERTIES=$PROJECT_HOME/conf/logging.properties

if [ "$1" = 'openidm' ]; then

    # reset IDM crypto. the function is sourced from commands.sh
    reset_idm_crypto

    HOSTNAME=`hostname`
    NODE_ID=${HOSTNAME}

    # If secrets keystore is present copy files from the secrets directory to the standard location.
    if [ -r secrets/keystore.jceks ]; then
        echo "Copying Keystores"
        cp -L secrets/*  security
    fi

    # Copy any patch files to the project home
    cp $IDM_HOME/conf/*.patch ${PROJECT_HOME}/conf

    # Bundle directory
    BUNDLE_PATH="$IDM_HOME/bundle"

    # Find any file in the bundle directory based on a wildcard
    find_bundle_file () {
        echo "$(find ${BUNDLE_PATH} -name $1)"
    }

    SLF4J_API=$(find_bundle_file "slf4j-api-[0-9]*.jar")
    SLF4J_JDK14=$(find_bundle_file "slf4j-jdk14-[0-9]*.jar")
    JACKSON_CORE=$(find_bundle_file "jackson-core-[0-9]*.jar")
    JACKSON_DATABIND=$(find_bundle_file "jackson-databind-[0-9]*.jar")
    JACKSON_ANNOTATIONS=$(find_bundle_file "jackson-annotations-[0-9]*.jar")

    SLF4J_PATHS="$SLF4J_API:$SLF4J_JDK14"
    JACKSON_PATHS="$JACKSON_CORE:$JACKSON_DATABIND:$JACKSON_ANNOTATIONS"
    IDM_SYSTEM_PATH=$(echo $BUNDLE_PATH/openidm-system-*.jar)
    IDM_UTIL_PATH=$(echo $BUNDLE_PATH/openidm-util-*.jar)
    CLASSPATH="$IDM_HOME/bin/*:$IDM_HOME/framework/*:$SLF4J_PATHS:$JACKSON_PATHS:$IDM_SYSTEM_PATH:$IDM_UTIL_PATH"

   exec tini -v -- java \
       "-Djava.util.logging.config.file=${LOGGING_PROPERTIES}" \
        ${JAVA_OPTS}  \
       -Djava.endorsed.dirs="$JAVA_ENDORSED_DIRS" \
       -classpath "$CLASSPATH" \
       -Dopenidm.system.server.root=$IDM_HOME/openidm \
       -Djava.endorsed.dirs= \
       -Djava.awt.headless=true \
       -Dopenidm.node.id="${NODE_ID}" \
       org.forgerock.openidm.launcher.Main -c $IDM_HOME/bin/launcher.json \
       -p "${PROJECT_HOME}"
fi

# Else - exec the arguments pass to the entry point.
exec  "$@"
