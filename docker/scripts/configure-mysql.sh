#!/bin/bash
/usr/bin/mysqld_safe &
sleep 3
/usr/bin/mysql -u root -e "CREATE DATABASE horde_test;"
/usr/bin/mysql -u root horde_test < /horde/schema.sql
