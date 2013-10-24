FROM ubuntu:12.10

MAINTAINER Nick Payne <nick@kurai.co.uk>

ENV DEBIAN_FRONTEND noninteractive

# Make sure we're all up to date with package sources
RUN apt-get -y update

# stop ubuntu services whinging about upstart stuff
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -s /bin/true /sbin/initctl

# a nice base directory we'll put everything in
RUN mkdir /horde

# MySQL & PHP5 and other base stuff
RUN apt-get -y install wget mysql-client mysql-server php5 php5-mysql
# includes extras to satify the wordpress test suite I used as a testbed
RUN apt-get -y install sendmail imagemagick php5-imagick

# PHPUnit, nice and simple install
RUN wget https://phar.phpunit.de/phpunit.phar --no-check-certificate -P /horde
RUN chmod +x /horde/phpunit.phar
RUN mv /horde/phpunit.phar /usr/local/bin/phpunit

# nodejs - custom PPA for latest version
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:chris-lea/node.js
RUN apt-get update
RUN apt-get install -y nodejs
RUN npm install -g coffee-script

# make the MySQL startup script available & executable
ADD ./scripts/start-mysql.sh /horde/start-mysql
RUN chmod +x /horde/start-mysql

# DB setup
ADD ./scripts/configure-mysql.sh /horde/configure-mysql.sh
RUN /bin/bash /horde/configure-mysql.sh

ADD scripts/boot.coffee /horde/boot.coffee
RUN chmod +x /horde/boot.coffee
