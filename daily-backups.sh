#!/bin/bash

# SSH host, username and port
# of the remote host.
nas_user="tower"
nas_host="192.168.1.102"
nas_ssh_key="$HOME/.ssh/backup.pub"
nas_port=22

# Location to save the local backups
backupdate=$(date +%F)
backup_location="$HOME/backup_${backupdate}_${RANDOM}.tar.gz"

# The remote destination supplied to rsync
backup_desitnation="/cygdrive/e/Automated\ Backups"

# List of folders to backup into the single tar file.
backup_sources[0]="$HOME/Data"
backup_sources[1]="$HOME/Daily-Backups"
backup_sources[2]="/var/www/html"

log_error=~/nightly_backup.log

# If enabled, remote host 
# will not be turned on 
# and file transfer will occur.
dry_run=0

# A shutdown request will be sent
# to the host after the transfer
# is complete. THis is disabled if 
# this value is set to 0
shutdown_remote_after_transfer=1


# Number attempts to 
# to wait for Host bootup before
# aborting.
readytimeoutlimit=10
readycheckdelay=5


function log {
    local timestamp=$(date)

    if [ $dry_run -eq 1 ]; then
        local logstr="[DRY RUN][$timestamp]: "
    else
        local logstr="[$timestamp]: "
    fi
    printf "$logstr$1\n"

}

# Checks to see if the Host is awake 
# and the windows share is ready 
# to serve files.
function checkHost {
    pacready=false

    # Check basic ping packet response
    if ping -c 1 $nas_host &> /dev/null; then
            log "Host is responding to ping."
    fi

    # Check ssh request response
    if nmap -Pn $nas_host -p $nas_port | grep "open" > /dev/null; then
        log "Host is responding to SSH requests"
        pcready=true
    fi

    if [ $dry_run -eq 1 ]; then
        pcready=true
    fi
}


if [ $dry_run -eq 1 ]; then
    log " --------------- DRY RUN ------------ "
fi


log "BACKUP SOURCE: $backup_sources"
log "BACKUP DESTINATION: $backup_desitnation"
log "BACKUP LOCATION: $backup_location"
log "Waking the PC..."

# Check to see if the host is already awake
checkHost

# Don't shut it down if it was already
# running.
if [ $pcready = true ]; then
    log "Host is already awake. Disabling shutdown after transfer..."
    shutdown_remote_after_transfer=0
fi

if [ $dry_run -ne 1 ]  && [ $pcready = true ]; then
        if /usr/local/bin/awake -f ~/mac.list >/dev/null ; then
            log "Sent magic packet to host..."
        else
            log "An error occured while sending manage packet to host."
        fi
fi

# Wait until Host is up...
trycount=1
while true; do
    # We were unable to establish contact with
    # the server. Bail out.
    if [ "$trycount" -gt $readytimeoutlimit ]; then
        log "Timing out..."
        exit 1
    fi

    log "Attempting to contact Host ($nas_host)"
    checkHost 

    if [ "$pcready" = true ]; then
        log "Host is awake..."
        break
    else
        log "Host not responding..."
    fi 

    log "Waiting for Host to be ready ($trycount/$readytimeoutlimit)..."

    trycount=$(($trycount+1))
done


# Now that the Host is up and running,
# begin the compression of files
log "Preparing backup..."

# Combine the backup location array into a single string
for backup_source in "${backup_sources[@]}"; do
    backup_source_combined="$backup_source_combined $backup_source"
done

log "Combined backup locations: $backup_source_combined"
if tar zcvf $backup_location $backup_source_combined > /dev/null; then
    log "Successfully generated backups..."
else 
    log "Failed at creating backups..."
    exit 1
fi

log "Sending backup to remote..."
if [ $dry_run -ne 1 ]; then
    if rsync -azv $backup_location -e ssh -i $nas_ssh_key "$nas_user@$nas_host:$backup_desitnation"; then
        log "Successfully transfered backup to remote!"
    else 
        log "An error occurred during file backup..."
    fi
fi

if [ $shutdown_remote_after_transfer -eq 1 ] && [ $dry_run -ne 1 ]; then
    log "Shutting down host..."
    ssh $nas_user@$nas_host "shutdown -t 0 -s"
fi

log "\n=====================================\n"
