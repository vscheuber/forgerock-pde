#!/bin/sh
cd "$(dirname "$0")"

# update am.war
jar -uvf am.war WEB-INF
