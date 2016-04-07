#!/bin/bash

help() {
    echo 'Make requests to the Nginx stub_status endpoint and pull out metrics'
    echo 'for the telemetry service. Refer to the Nginx docs for details:'
    echo 'http://nginx.org/en/docs/http/ngx_http_stub_status_module.html'
}

# Cummulative number of dropped connections
unhandled() {
    local scraped=$(curl -s localhost/health)
    local accepts=$(echo ${scraped} | awk 'FNR == 3 {print $1}')
    local handled=$(echo ${scraped} | awk 'FNR == 3 {print $2}')
    echo $(expr ${accepts} - ${handled})
}

# ratio of connections-in-use to available workers
connections_load() {
    local scraped=$(curl -s localhost/health)
    local active=$(echo ${scraped} | awk '/Active connections/{print $3}')
    local waiting=$(echo ${scraped} | awk '/Reading/{print $6}')
    local workers=$(echo $(cat /etc/nginx/nginx.conf | perl -n -e'/worker_connections *(\d+)/ && print $1')
)
    echo $(echo "scale=4; (${active} - ${waiting}) / ${workers}" | bc)
}

# -------------------------------------------------------
# Un-scraped metrics; these raw metrics are available but we're not going
# to include them in the telemetry configuration. They have been left here
# as an example.

# The current number of active client connections including Waiting connections.
connections_active() {
    curl -s localhost/health | awk '/Active connections/{print $3}'
}

# The current number of connections where nginx is reading the request header.
connections_reading() {
    curl -s localhost/health | awk '/Reading/{print $2}'
}

# The current number of connections where nginx is writing the response back
# to the client.
connections_writing() {
    curl -s localhost/health | awk '/Reading/{print $4}'
}

# The current number of idle client connections waiting for a request.
connections_waiting() {
    curl -s localhost/health | awk '/Reading/{print $6}'
}

# The total number of accepted client connections.
accepts() {
    curl -s localhost/health | awk 'FNR == 3 {print $1}'
}

# The total number of handled connections. Generally, the parameter value is the
# same as accepts unless some resource limits have been reached (for example, the
# worker_connections limit).
handled() {
    curl -s localhost/health | awk 'FNR == 3 {print $2}'
}

# The total number of client requests.
requests() {
    curl -s localhost/health | awk 'FNR == 3 {print $3}'
}

# -------------------------------------------------------

cmd=$1
if [ ! -z "$cmd" ]; then
    shift 1
    $cmd "$@"
    exit
fi

help
