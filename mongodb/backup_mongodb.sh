#!/usr/bin/env bash

# Configuration, EDIT AS NEEDED
: ${mongo_dbs="db1 db2 db3"}
: ${mongo_host=localhost}
: ${mongo_port=27017}
: ${tag_name=`hostname`}
: ${tag_date=`/bin/date +%a`}
: ${tag="$tag_name.$tag_date"}
: ${dump_path="/var/tmp/mongo"}
: ${dump_name="{db}.${tag}.bk.gz"}
: ${scp_host=}
: ${cp_path=}
: ${max_dump_days=}

# Verify mongod is running on this node
if [[ $mongo_host == "localhost" ]] && ! pidof mongod </dev/null >/dev/null 2>&1; then
  echo "ERROR: No mongod process running on localhost to dump" >&2
  exit 1
fi

# Check to make sure path exists, or can be created
if ! mkdir -p $dump_path; then
  echo "ERROR: Failed to create $dump_path directory. Unable to proceed" >&2
  exit 1
fi

# Verify we have a mongodump binary
if ! which mongodump </dev/null >/dev/null 2>&1 ; then
  echo "ERROR: no mongodump binary exist" >&2
  exit 1
fi

# Cleanup old dumps first, only report errors, don't exit
if [ $max_dump_days ]; then
  echo "INFO: Cleaning up old dumps before starting backups"
  if ! find $dump_path -type f -name ${dump_name/\{db\}*/}* -mtime +$max_dump_days -exec rm -vf {} \;; then
    echo "ERROR: Failed to cleanup old dumps" >&2
  fi
fi

echo "Starting Mongo Backup `date`"
for db in ${mongo_dbs}; do
  tmp_dump_path=${dump_path}/${dump_name/\{db\}/${db}}
  echo "INFO: Backup $db to $tmp_dump_path"

  # Dump our db, report an error but don't exit on failure
  if mongodump --host $mongo_host --db $db | gzip > $tmp_dump_path; then
    echo "ERROR: Failed to dump $db from $mongo_host" >&2
  else 
    # Copy our dump to other hosts/directory for safe keeping if specified
    [ $cp_path ] && cp ${tmp_dump_path} $cp_path
    [ $scp_host ] && scp $scp_host:$dump_path
  fi
  echo;
done

