#!/usr/bin/bash


# Setting to 1 prevents copying compressed back to 
# the destination directory
dry_run=1
destination=/nas/pc_backups
timestamp="$(date +%F_%H%M%S)"
backup_file="backup_$timestamp.tar.gz"

tar czvf  "$backup_file" /home /var /etc --exclude "/home/media/squidcache"


# move the backup to its destination
if [ "$dry_run" -eq 1 ]; then
    echo "Skipping copying backup to destination..."
else
    echo "Copying backup to destination..."
    mv "$backup_file" "$destination"
fi







