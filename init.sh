#!/bin/sh
cd "$(dirname "$0")"

echo "Initialization of your ForgeRock Personal Development Environment"
echo "================================================================="
echo ""
echo "This will initialize (on first run) or reset (on subsequent runs)"
echo "your ForgeRock Personal Development Environment (PDE). Use with"
echo "caution!"

# update am.war
./am/build/resources/update_war.sh

# initialize IDM config
./idm/run/init_config.sh