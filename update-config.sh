#!/bin/bash

if [ -z "$TB_CONFIG" ]; then
    # fetch latest config template from Consul k/v
    curl -s --fail consul:8500/v1/kv/touchbase/template?raw > /tmp/config.json.ctmpl
else
    # dump the $TB_CONFIG environment variable as a file
    echo $TB_CONFIG > /tmp/config.json.ctmpl
fi

# render config template using values from Consul
consul-template \
    -once \
    -consul consul:8500 \
    -template "/tmp/config.json.ctmpl:/usr/local/lib/node_modules/Couch411/config.json"
