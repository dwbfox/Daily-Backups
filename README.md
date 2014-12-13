# Nightly Backups


The backup shell script I use to facilitate daily backups of my files
to a remote PC.

----------

## What it does ##

 1. Using Python's `awake` library, a WoLAN magic packet signal is sent to the specified host computer, in my particular case my NAS/Tower computer with a 2TB storage.
 2. Using a combination of `ping` and `nmap`, the scripts checks to see if the remote host is fully up and running and the SSH daemon is ready to accept connections. A timeout occurs after a specified period of attempts.
 3. A list of backup sources, specified by `$backup_sources` is used tocreate tar archives of the files.
 4. `rsync` is used in tandem with an ssh key to authenticate to the remote host and make the transfer.
 5. After the transfer process completes, a shutdown signal is sent to power down the remote host. 

