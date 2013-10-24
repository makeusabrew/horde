FROM horde/base

MAINTAINER Nick Payne <nick@kurai.co.uk>

## LAMP base box


# Put the AMP in ‘LAMP’
RUN apt-get -y install mysql-client mysql-server apache2 libapache2-mod-php5 php5-mysql

# php default timezone
# @see https://gist.github.com/taion809/6850072
RUN perl -pi -e "s#;date.timezone =#date.timezone = Europe/London#g" /etc/php5/apache2/php.ini

# any custom apache modules
RUN a2enmod rewrite

# scrap the default apache vhost
RUN rm -f /etc/apache2/sites-enabled/000-default

# config sub dir
RUN mkdir /horde/conf
RUN touch /horde/conf/apache.conf
RUN ln -s /horde/conf/apache.conf /etc/apache2/sites-enabled/000-default

# make the apache startup script available & executable
ADD ./scripts/start-apache.sh /horde/start-apache
RUN chmod +x /horde/start-apache

# make the MySQL startup script available & executable
ADD ./scripts/start-mysql.sh /horde/start-mysql
RUN chmod +x /horde/start-mysql

# DB setup
ADD ./scripts/configure-mysql.sh /horde/configure-mysql.sh
RUN /bin/bash /horde/configure-mysql.sh
