# a minimal Nginx container including containerbuddy and a simple virtulhost config
FROM nginx:latest

# install some tooling
RUN apt-get update && \
    apt-get install -y \
    curl \
    bc \
    unzip && \
    rm -rf /var/lib/apt/lists/*

RUN curl -Lo /tmp/consul_template_0.11.0_linux_amd64.zip https://github.com/hashicorp/consul-template/releases/download/v0.11.0/consul_template_0.11.0_linux_amd64.zip && \
    unzip /tmp/consul_template_0.11.0_linux_amd64.zip && \
    mv consul-template /bin

# get Containerbuddy release
ENV CONTAINERBUDDY_VERSION 1.4.0-rc3
RUN export CB_SHA1=24a2babaff53e9829bcf4772cfe0462f08838a11 \
    && mkdir -p /opt/containerbuddy \
    && curl -Lso /tmp/containerbuddy.tar.gz \
         "https://github.com/joyent/containerbuddy/releases/download/${CONTAINERBUDDY_VERSION}/containerbuddy-${CONTAINERBUDDY_VERSION}.tar.gz" \
    && echo "${CB_SHA1}  /tmp/containerbuddy.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerbuddy.tar.gz -C /opt/containerbuddy \
    && rm /tmp/containerbuddy.tar.gz

# Add our configuration files and scripts
COPY opt/containerbuddy /opt/containerbuddy/
