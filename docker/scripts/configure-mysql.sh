#!/bin/bash
/horde/start-mysql &
sleep 3
echo "Creating horde_test database..."
/usr/bin/mysql -u root -e "CREATE DATABASE horde_test;"
