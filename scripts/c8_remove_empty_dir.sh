#!/bin/bash

# This script deletes empty keyspaces directories in Cassandra's installation directory
# Run as root/sudo.

c8_data_dir='/var/lib/cassandra/data'

if [ -d "$c8_data_dir" ]; then
  echo "Deleting all empty directories under $c8_data_dir..."
  find $c8_data_dir -type d -empty -exec rmdir {} \;
fi
