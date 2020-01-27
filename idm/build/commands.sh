#!/bin/bash

#
# Copyright 2020 ForgeRock AS
#

# IDM repository (DS) configuration variables
export DS_HOME="/opt/forgerock/idm/openidm/db/openidm/opendj"
export DS_SNAPSHOT_DIR="/opt/forgerock/idm/snapshot"
export DS_BACKUP_USER="cn=Directory Manager"
export DS_PASSWORD="${IDM_PASSWORD}"
export PROJECT_HOME="/opt/forgerock/idm/project/pde"

#
# Backup idmRepo from DS
#
function backup_idmRepo() {
    echo "Backing up IDM data from DS..."
    BACKUP_ID=${1:-`date '+%Y%m%d%H%M%S'`}
    cd ${DS_HOME}/bin
    ./backup \
      --hostname localhost \
      --port 34444 \
      --bindDN "${DS_BACKUP_USER}" \
      --bindPassword password \
      --backendId idmRepo \
      --backupId $BACKUP_ID \
      --backupDirectory $DS_SNAPSHOT_DIR/$BACKUP_ID \
      --start 0 \
      --trustAll
    cd - &>/dev/null
}

#
# Restore idmRepo to DS
#
function restore_idmRepo() {
    echo "Restoring IDM data to DS..."
    BACKUP_ID=${1:-`date '+%Y%m%d%H%M%S'`}
    cd ${DS_HOME}/bin
    ./restore \
      --hostname localhost \
      --port 34444 \
      --bindDN "${DS_BACKUP_USER}" \
      --bindPassword password \
      --backupId $BACKUP_ID \
      --backupDirectory $DS_SNAPSHOT_DIR/$BACKUP_ID \
      --start 0 \
      --trustAll
    cd - &>/dev/null
}

#
# List available idmRepo backups
#
function list_idmRepo_backups() {
    echo "Available idmRepo backups to restore:"
    for BACKUP_DIR in $DS_SNAPSHOT_DIR/*/; do
        ${DS_HOME}/bin/restore --offline --listBackups --backupDirectory $BACKUP_DIR
    done
}

#
# Reset encrypted passwords in IDM configuration files
#
function reset_idm_crypto() {
    echo "Resetting encrypted passwords in IDM configuration files"
    for f in $(grep -l "\$crypto" $PROJECT_HOME/conf/*.json); do
        echo "Resetting $f"
        jq --arg cleartext "$IDM_PASSWORD" -f /opt/forgerock/idm/bin/decrypt.jq $f > $f.tmp && mv $f.tmp $f
    done
    cd - &>/dev/null
}