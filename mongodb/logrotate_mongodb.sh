#!/usr/bin/env bash

: ${log_dir=/var/log/mongo}
: ${log_pattern='mongo[0-9].log.[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]-[0-9][0-9]-[0-9][0-9]'}
: ${log_days=7}

# Verify our log directory exists
if [ ! -d $log_dir ]; then
  echo "ERROR: Log directory $log_dir does not exist. Exiting"
  exit 1
fi

# Verify mongod is running
if ! pidof mongod </dev/null >/dev/null 2>&1; then
  echo "ERROR: No mongod process running. Not rotating logs"
  exit 1
fi

# Force mongo to rotate its log
if ! /usr/bin/killall -SIGUSR1 mongod </dev/null; then
  echo "WARNING: Problem was encountered issuing SIGUSR1 signal to mongod"
fi

# Compress recently rotated log
if ! find $log_dir -name $log_pattern -exec gzip {} \;; then
  echo "WARNING: Problem encountered while compressing rotated logs"
fi

# Remove old logs
if ! find $log_dir -name $log_pattern\.gz -mtime +$log_days -exec unlink {} \;; then
  echo "WARNING: Unable to cleanup old logs"
fi
