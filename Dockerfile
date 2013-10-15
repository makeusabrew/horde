FROM ubuntu:12.10

MAINTAINER Nick Payne <nick@kurai.co.uk>

RUN apt-get -y update

# stop ubuntu services whinging about upstart stuff
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -s /bin/true /sbin/initctl

# AMP stack - we need the noninteractive env variable otherwise we'll be prompted for config data
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install mysql-client mysql-server apache2 libapache2-mod-php5 php5-mysql

# php default timezone
# @see https://gist.github.com/taion809/6850072
RUN perl -pi -e "s#;date.timezone =#date.timezone = Europe/London#g" /etc/php5/apache2/php.ini

# ssh daemon
RUN apt-get -y install openssh-server
RUN mkdir /var/run/sshd

# nodejs - from source allows a custom node version
RUN apt-get install -y git build-essential python
RUN git clone https://github.com/joyent/node.git /node -b v0.8.14
RUN cd /node && ./configure
RUN cd /node && make
RUN cd /node && make install

# global npm modules
RUN npm install -g coffee-script

# any custom apache modules
RUN a2enmod rewrite

ADD ./apache2.sh /etc/apache2/start.sh
RUN chmod +x /etc/apache2/start.sh

# test DB setup and initial schema
ADD ./conf/schema.sql /schema.sql
ADD ./mysql-db.sh /mysql-db.sh
RUN chmod +x /mysql-db.sh
RUN /mysql-db.sh
RUN rm /mysql-db.sh
RUN rm /schema.sql

ADD ./conf/all-vhosts.conf /etc/apache2/sites-enabled/000-default

ADD run.coffee /run.coffee
