# a minimal Nginx container including Containerbuddy and a simple virtulhost config
FROM nginx:latest

# install curl and jq
RUN apt-get update && \
    apt-get install -y \
    curl \
    unzip && \
    rm -rf /var/lib/apt/lists/*

# we use consul-template to re-write our Nginx virtualhost config
RUN curl -Lo /tmp/consul_template_0.11.0_linux_amd64.zip https://github.com/hashicorp/consul-template/releases/download/v0.11.0/consul_template_0.11.0_linux_amd64.zip && \
    unzip /tmp/consul_template_0.11.0_linux_amd64.zip && \
    mv consul-template /bin

# get Containerbuddy release
RUN export CB=containerbuddy-0.0.1-alpha &&\
    mkdir -p /opt/containerbuddy && \
    curl -Lo /tmp/${CB}.tar.gz \
    https://github.com/joyent/containerbuddy/releases/download/0.0.1-alpha/${CB}.tar.gz && \
	tar -xf /tmp/${CB}.tar.gz && \
    mv /build/containerbuddy /opt/containerbuddy/

# add Containerbuddy and all our configuration
ADD opt/containerbuddy /opt/containerbuddy/
ADD etc/nginx/conf.d /etc/nginx/conf.d/
