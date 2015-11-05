# a Node.js application container including Containerbuddy
FROM node:slim

# install curl
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    graphicsmagick \
    python \
    git \
    unzip \
    curl && \
    rm -rf /var/lib/apt/lists/*

# touchbase is our application
# node-gyp is required to support the Couchbase C libs for Node
RUN git clone https://github.com/couchbaselabs/touchbase.git /tmp && \
    npm install -g \
    node-gyp \
    bower \
    /tmp/TouchbaseModular

RUN cd /usr/local/lib/node_modules/Couch411 && \
    echo '{ "allow_root": true }' > /root/.bowerrc && \
    bower install

# we use consul-template to re-write our config.json
RUN curl -Lo /tmp/consul_template_0.11.0_linux_amd64.zip https://github.com/hashicorp/consul-template/releases/download/v0.11.0/consul_template_0.11.0_linux_amd64.zip && \
    unzip /tmp/consul_template_0.11.0_linux_amd64.zip && \
    mv consul-template /usr/local/bin

# get Containerbuddy release
RUN export CB=containerbuddy-0.0.1-alpha &&\
    mkdir -p /opt/containerbuddy && \
    curl -Lo /tmp/${CB}.tar.gz \
    https://github.com/joyent/containerbuddy/releases/download/0.0.1-alpha/${CB}.tar.gz && \
	tar -xf /tmp/${CB}.tar.gz && \
    mv /build/containerbuddy /opt/containerbuddy/

# add Containerbuddy and configuration
COPY touchbase.json /opt/containerbuddy/
COPY update-config.sh /opt/containerbuddy/

# add our starting application configuration
COPY run-touchbase.sh /usr/local/bin/run-touchbase.sh
COPY config.json /usr/local/lib/node_modules/Couch411/config.json

# generate a self-signed cert. We would terminate any SSL at the load balancer but
# Touchbase won't start without at least a self-signed cert installed.
RUN openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes \
    -subj "/C=US/ST=None/L=None/O=None/CN=example.com"
