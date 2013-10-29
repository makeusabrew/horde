# horde meta: build as horde/module-phpunit-lamp
FROM horde/base-lamp

MAINTAINER Nick Payne <nick@kurai.co.uk>

RUN apt-get -y update

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install wget mysql-client mysql-server php5 php5-mysql
# includes extras to satify the wordpress test suite I used as a testbed
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install sendmail imagemagick php5-imagick

# PHPUnit, nice and simple install
RUN wget https://phar.phpunit.de/phpunit.phar --no-check-certificate -P /horde
RUN chmod +x /horde/phpunit.phar
RUN mv /horde/phpunit.phar /usr/local/bin/phpunit

ADD scripts/boot.coffee /horde/boot
RUN chmod +x /horde/boot
