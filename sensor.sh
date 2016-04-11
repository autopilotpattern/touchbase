#!/bin/bash

help() {
    echo 'Get memory information about the Touchbase service.'
}

mem_used() {
    free -m | awk '/Mem/{print $3}'
}

mem_free() {
    free -m | awk '/Mem/{print $4}'
}

# -------------------------------------------------------

cmd=$1
if [ ! -z "$cmd" ]; then
    shift 1
    $cmd "$@"
    exit
fi

help
