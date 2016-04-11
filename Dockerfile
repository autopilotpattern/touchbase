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

# touchbase is our application; we're using a fork that removes
# the requirement for SendGrid verification of emails
# node-gyp is required to support the Couchbase C libs for Node
RUN git clone -b no_sendgrid https://github.com/tgross/touchbase.git /tmp && \
    npm install -g \
    node-gyp \
    bower \
    /tmp/TouchbaseModular

RUN cd /usr/local/lib/node_modules/Couch411 && \
    echo '{ "allow_root": true }' > /root/.bowerrc && \
    bower install

# generate a self-signed cert. We would terminate any SSL at the load balancer but
# Touchbase won't start without at least a self-signed cert installed.
RUN openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes \
    -subj "/C=US/ST=None/L=None/O=None/CN=example.com"

# we use consul-template to re-write our config.json
RUN curl -Lo /tmp/consul_template_0.11.0_linux_amd64.zip https://github.com/hashicorp/consul-template/releases/download/v0.11.0/consul_template_0.11.0_linux_amd64.zip && \
    unzip /tmp/consul_template_0.11.0_linux_amd64.zip && \
    mv consul-template /usr/local/bin

# get Containerbuddy release
ENV CONTAINERBUDDY_VERSION 1.4.0-rc3
RUN export CB_SHA1=24a2babaff53e9829bcf4772cfe0462f08838a11 \
    && mkdir -p /opt/containerbuddy \
    && curl -Lso /tmp/containerbuddy.tar.gz \
         "https://github.com/joyent/containerbuddy/releases/download/${CONTAINERBUDDY_VERSION}/containerbuddy-${CONTAINERBUDDY_VERSION}.tar.gz" \
    && echo "${CB_SHA1}  /tmp/containerbuddy.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerbuddy.tar.gz -C /opt/containerbuddy \
    && rm /tmp/containerbuddy.tar.gz

# add Containerbuddy and configuration
COPY touchbase.json /opt/containerbuddy/
COPY update-config.sh /opt/containerbuddy/
COPY sensor.sh /opt/containerbuddy/
