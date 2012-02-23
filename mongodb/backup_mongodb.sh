#!/usr/bin/env bash

# Configuration, EDIT AS NEEDED
: ${mongo_dbs="db1 db2 db3"}
: ${mongo_host=localhost}
: ${mongo_port=27017}
: ${tag_name=`hostname`}
: ${tag_date=`/bin/date +%a`}
: ${tag="$tag_name.$tag_date"}
: ${dump_path="/var/tmp"}
: ${dump_name="{db}.${tag}.bk.gz"}
: ${scp_host=}
: ${cp_path=}

# Verify mongod is running on this node
if [[ $mongo_host == "localhost" ]] && ! pidof mongod; then
  echo "ERROR: No mongod process running on localhost to dump" >&2
  exit 1
fi

if ! which mongod </dev/null >/dev/null 2>&1 ; then
  echo "ERROR: no mongodump binary exist" >&2
  exit 1
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

