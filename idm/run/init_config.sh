#!/bin/sh
cd "$(dirname "$0")"

echo Initializing IDM configuration...
if [ -d config/idm/conf ] ; then
    read -p "Existing IDM run-time configuration found. Do you want to continue and reset the IDM configuration? (N/y): " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]] ; then
        echo "Resetting IDM configuration..."
        rm -rf config/idm/*
    else
        1>&2 echo "Aborted."
        exit 0
    fi
fi
cp -av ../build/config/idm/ config/idm
echo Done.