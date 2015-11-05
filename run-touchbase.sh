#!/bin/bash

# run-touchbase.sh bootstraps Touchbase by updating its configuration
# file at least once prior to starting up. We need this in order to get
# a runtime hostname for Couchbase at startup.
/opt/containerbuddy/update-config.sh && \
    node /usr/local/lib/node_modules/Couch411/app.js
