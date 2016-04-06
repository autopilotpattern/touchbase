#!/bin/bash

help() {
    echo 'Make requests to the Nginx stub_status endpoint and pull out metrics'
    echo 'for the telemetry service. Refer to the Nginx docs for details:'
    echo 'http://nginx.org/en/docs/http/ngx_http_stub_status_module.html'
}

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


# -------------------------------------------------------
# Un-scraped metrics; these metrics are available but not very interesting
# so we're not going to include them in the telemetry configuration. They
# have been left here as an example.

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
