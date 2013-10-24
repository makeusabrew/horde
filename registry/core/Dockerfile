# horde meta: build as horde/core
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

# ssh daemon
RUN mkdir /var/run/sshd
RUN apt-get -y install openssh-server

# @NOTE for now all horde images rely on nodejs and CoffeeScript
# This is because all boot scripts are assumed to be written in CS
# will change one day... maybe...

# nodejs - custom PPA for latest version
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:chris-lea/node.js
RUN apt-get update
RUN apt-get install -y nodejs
RUN npm install -g coffee-script
