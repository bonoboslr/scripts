#!/bin/bash

# VARS
log_file=/var/log/snapshot.log
vg=/dev/vg_mysql
lv=lv_mysql
mountdir=/mnt/snapshot
pidfile=/var/run/mysqld/mysql_3307.pid

LV_SIZE="`lvs --units m --noheading --nosuffix $vg/$lv | cut -d ' ' -f 6`"
LV_UUID="`lvdisplay $vg/$lv|grep 'LV UUID'|sed 's/  LV UUID                //g'`"

DATE=`date +%Y%m%d%H`
YEAR=`date +%Y`
MONTH=`date +%B`
DAY=`date +%d`
HOUR=`date +%H`
MIN=`date +%M`
NAME=`hostname`

lvsnap=$lv"_snap-$DATE"

function info {
log "$DATE $HOUR:$MIN INFO - $1"
}

function error {
log "$DATE $HOUR:$MIN ERROR - $1"
}

# Functions
function log {
echo "$1" >> $log_file
}

function create_snap {
lvcreate --quiet -L 10G -s -n $lvsnap $vg/$lv
rc=$?
if [[ $rc == 0 ]]; then
	info "Snapshot $lvsnap created"
else
	if [[ $rc == 5 ]]; then 
		#Snapshot already exists
		info "Warning ... Snapshot creation failed - snapshot already exist"
	else
		error "Snapshot creation failed - reason unknown"
		exit 1
	fi
fi
}

function mount_snap {
mount $vg/$lvsnap $mountdir

if [[ $? != 0 ]]; then
	error "Failed to mount Snapshot Volume to $mountdir"
	exit 1
else
	info "Snapshot mounted to $mountdir"
fi
}

function backup_data {
# Create Backup dir

BACKUP_DIR=/mnt/nfs_backup/$NAME/$YEAR/$MONTH/$DAY/$HOUR

date1=$(date +"%s")
mkdir -p $BACKUP_DIR
rsync -avzhc --delete $mountdir/* $BACKUP_DIR 2>&1 | grep 'sent' | sed -e 's/sent /                 INFO - sent /g' |tee -a $log_file
if [[ $? != 0 ]]; then 
	error "Rsync copy failed."
	exit 1
else
	date2=$(date +"%s")
	diff=$(($date2-$date1))
	info "Copy of Backup data took $(($diff / 60)) minutes and $(($diff % 60)) seconds"
fi

umount $mountdir
lvremove --quiet -f $vg/$lvsnap
}

function start_mysql {
# Start MYSQL on port 3307
mysqld_safe --datadir="$mountdir" --pid-file="$pidfile" --port=3307 &
if [[ -e $pidfile ]]; then
	PID="`cat $pidfile`"
	info "MySQL running on port 3307 with PID : $PID"
else
	error "Failed to Start MySQL on port 3307"
	exit 1
fi
}

# Start Main
info "*** Starting Backup"

# Setup the SNAP
create_snap

# Mount Snapshot
mount_snap

# Backup Data
backup_data
info "=== Backup Completed"

exit 0
