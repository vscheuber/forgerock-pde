#!/bin/sh
cd "$(dirname "$0")"

echo Initializing IDM configuration...
cp -av ../build/config/idm/ config/idm
echo Done.