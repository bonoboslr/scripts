#!/bin/bash

# VARS
log_file=/var/log/snapshot.log
vg=/dev/vg_spacewalk
lv=lv_mysqldata
mountdir=/mnt/snapshot
pidfile=/var/run/mysqld/mysql_3307.pid

LV_SIZE="`lvs --units m --noheading --nosuffix $vg/$lv | cut -d ' ' -f 6`"
LV_UUID="`lvdisplay $vg/$lv|grep 'LV UUID'|sed 's/  LV UUID                //g'`"

DATE=`date +%Y%m%d`
YEAR=`date +%Y`
MONTH=`date +%B`
HOUR=`date +%H`
MIN=`date +%M`

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
lvcreate -L 10G -s -n $lvsnap $vg/$lv
rc=$?
if [[ $rc == 0 ]]; then
	info "Snapshot $lvsnap created"
else
	if [[ $rc == 5 ]]; then 
		#Snapshot already exists
		error "Snapshot creation failed - snapshot already exist"
		exit 1
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
info "Starting Backup"

# Setup the SNAP
create_snap

# Mount Snapshot
mount_snap


# Removing Existing Snap
echo “"Logical Volume: $lv"; 
echo “"Size: $LV_SIZE MB"; 
echo “"UUID: $LV_UUID"; 
echo “"Snapshot name: $lvsnap"; 

exit 0
