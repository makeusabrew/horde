FROM ubuntu:12.10

MAINTAINER Nick Payne <nick@kurai.co.uk>

# Make sure we're all up to date with package sources
RUN apt-get -y update

# stop ubuntu services whinging about upstart stuff
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -s /bin/true /sbin/initctl

# a nice base directory we'll put everything in
RUN mkdir /horde

# Put the AMP in ‘LAMP’ - we need the noninteractive env variable otherwise we'll be prompted for config data
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-client mysql-server apache2 libapache2-mod-php5 php5-mysql

# php default timezone
# @see https://gist.github.com/taion809/6850072
RUN perl -pi -e "s#;date.timezone =#date.timezone = Europe/London#g" /etc/php5/apache2/php.ini

# ssh daemon
RUN apt-get -y install openssh-server
RUN mkdir /var/run/sshd

# nodejs - see branch node-from-source to build from source (MUCH slower!)
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:chris-lea/node.js
RUN apt-get update -y
RUN apt-get install -y nodejs

# global npm modules
RUN npm install -g coffee-script

# any custom apache modules
RUN a2enmod rewrite

# make the apache startup script available & executable
ADD ./scripts/start-apache.sh /horde/start-apache.sh
RUN chmod +x /horde/start-apache.sh

# DB setup and initial schema import
ADD ./conf/schema.sql /horde/schema.sql
ADD ./scripts/configure-mysql.sh /horde/configure-mysql.sh
RUN chmod +x /horde/configure-mysql.sh
RUN /horde/configure-mysql.sh

# copy our custom vhost configuration over the default
ADD ./conf/all-vhosts.conf /etc/apache2/sites-enabled/000-default

ADD scripts/boot.coffee /horde/boot.coffee
RUN chmod +x /horde/boot.coffee
