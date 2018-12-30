FROM ubuntu:latest
MAINTAINER Erez Buchnik  <erez@shrewdthings.com>

ARG IMG_INFLUXDB_VERSION=1.7.2
ARG IMG_GRAFANA_VERSION=5.4.2
ARG IMG_NODE_VERSION=10

ENV INFLUXDB_VERSION="${IMG_INFLUXDB_VERSION}"
ENV GRAFANA_VERSION="${IMG_GRAFANA_VERSION}"
ENV NODE_VERSION="${IMG_NODE_VERSION}"
ENV SRC_DIR=/usr/src

COPY app/ ${SRC_DIR}/
ENV BASH_ENV=${SRC_DIR}/docker-entrypoint.sh
SHELL ["/bin/bash", "-c"]


ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8

# Database Defaults
ENV INFLUXDB_GRAFANA_DB datasource
ENV INFLUXDB_GRAFANA_USER datasource
ENV INFLUXDB_GRAFANA_PW datasource

ENV GF_DATABASE_TYPE=sqlite3

# Fix bad proxy issue
COPY system/99fixbadproxy /etc/apt/apt.conf.d/99fixbadproxy

# Clear previous sources
RUN rm /var/lib/apt/lists/* -vf

# Base dependencies
RUN apt-get -y update && \
	apt-get -y dist-upgrade && \
	apt-get -y install \
	apt-utils \
	gnupg2 \
	ca-certificates \
	curl \
	git \
	htop \
	libfontconfig \
	nano \
	net-tools \
	openssh-server \
	supervisor \
	wget

RUN mkdir -p /var/log/supervisor && \
    mkdir -p /var/run/sshd && \
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo 'root:root' | chpasswd && \
    rm -rf .ssh && \
    rm -rf .profile && \
    mkdir .ssh

# Configure Supervisord, SSH and base env
RUN find ${SRC_DIR}/ -type f
RUN mv ${SRC_DIR}/supervisord/base.conf /etc/supervisor/conf.d/supervisord.conf
RUN cat $(ls -tr ${SRC_DIR}/supervisord/*.conf) >> /etc/supervisor/conf.d/supervisord.conf
COPY ssh/id_rsa .ssh/id_rsa
COPY bash/profile .profile

####################################
####################################

RUN curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
	apt-get install -y nodejs

WORKDIR /root

# Install InfluxDB
RUN wget https://dl.influxdata.com/influxdb/releases/influxdb_${INFLUXDB_VERSION}_amd64.deb && \
    dpkg -i influxdb_${INFLUXDB_VERSION}_amd64.deb && rm influxdb_${INFLUXDB_VERSION}_amd64.deb

# Install Grafana
RUN wget https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana_${GRAFANA_VERSION}_amd64.deb && \
    dpkg -i grafana_${GRAFANA_VERSION}_amd64.deb && rm grafana_${GRAFANA_VERSION}_amd64.deb

# Cleanup
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure InfluxDB
COPY influxdb/influxdb.conf /etc/influxdb/influxdb.conf
COPY influxdb/init.sh /etc/init.d/influxdb

# Configure Grafana
COPY grafana/grafana.ini /etc/grafana/grafana.ini

RUN chmod 0755 /etc/init.d/influxdb

COPY runtime/ ${SRC_DIR}/runtime/
RUN find ${SRC_DIR}/runtime/ -type f
ENV BASH_ENV=${SRC_DIR}/app-entrypoint.sh
WORKDIR ${SRC_DIR}
CMD ["/usr/bin/supervisord"]

