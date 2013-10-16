#!/bin/bash
/horde/start-mysql &
sleep 3
echo "Creating horde_test database..."
/usr/bin/mysql -u root -e "CREATE DATABASE horde_test;"
echo "Importing /horde/schema.sql..."
/usr/bin/mysql -u root horde_test < /horde/schema.sql
