#!/bin/sh
cd "$(dirname "$0")"

# update am.war
if [ -e am.war ]
then
    echo "Updating am.war..."
    jar -uvf am.war WEB-INF
else
    echo "am.war not found! Aborting. Please follow the instructions to download ForgeRock Access Management and rename it to am.war."
    exit 1
fi
