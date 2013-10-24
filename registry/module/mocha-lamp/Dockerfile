# horde meta: build as horde/module-mocha-lamp
FROM horde/base-lamp

MAINTAINER Nick Payne <nick@kurai.co.uk>

# Make sure we're all up to date with package sources
RUN apt-get -y update

# nodejs - custom PPA for latest version
#RUN apt-get install -y software-properties-common
#RUN add-apt-repository -y ppa:chris-lea/node.js
#RUN apt-get update -y
#RUN apt-get install -y nodejs
# alternatively we can build from source for a custom version but this is A LOT slower
RUN apt-get install -y git build-essential python
RUN git clone https://github.com/joyent/node.git /horde/node -b v0.8.14
RUN cd /horde/node && ./configure
RUN cd /horde/node && make
RUN cd /horde/node && make install

# global npm modules
RUN npm install -g coffee-script

ADD scripts/boot.coffee /horde/boot
RUN chmod +x /horde/boot
