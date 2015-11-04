#!/bin/bash
set -e -o pipefail

# default values which can be overriden by -f or -p flags
. .env
COMPOSE_CFG=
PREFIX=tb
CB_USER=${CB_USER:-Administrator}
CB_PASSWORD=${CB_PASSWORD:-password}
CB_RAM_QUOTA=${CB_RAM_QUOTA:-100}

usage() {
    echo 'Usage ./start.sh [-f docker-compose.yml] [-p project] [--no-index] [cmd] [args]'
    echo
    echo 'Starts up the entire stack.'
    echo
    echo '-f <filename> [optional] use this file as the docker-compose config file'
    echo '-p <project>  [optional] use this name as the project prefix for docker-compose'
    echo '-h            help. print this thing you are reading now.'
    echo
    echo 'Optionally pass a command and parameters and this script will execute just'
    echo 'that command, for testing purposes.'
}

prep() {
    echo "Starting example application"
    echo "project prefix:      $PREFIX"
    echo "docker-compose file: $CONFIG_FILE"
    echo
    echo 'Pulling latest container images'
    ${COMPOSE} pull
}

# get the IP:port of a container via either the local docker-machine or from
# sdc-listmachines.
getIpPort() {
    if [ -z "${COMPOSE_CFG}" ]; then
        local ip=$(sdc-listmachines --name ${PREFIX}_$1_1 | json -a ips.1)
        local port=$2
    else
        local ip=$(docker-machine ip default)
        local port=$(docker inspect ${PREFIX}_$1_1 | json -a NetworkSettings.Ports."$2/tcp".0.HostPort)
    fi
    echo "$ip:$port"
}

# start and initialize the Couchbase cluster, along with Consul
startDatabase() {
    echo
    echo 'Starting Couchbase'
    ${COMPOSE} up -d --no-recreate couchbase
    echo
    echo -n 'Initializing cluster.'

    sleep 1.3
    COUCHBASERESPONSIVE=0
    while [ $COUCHBASERESPONSIVE != 1 ]; do
        echo -n '.'
        RUNNING=$(docker inspect "${PREFIX}_couchbase_1" | json -a State.Running)
        if [ "$RUNNING" == "true" ]
        then
            docker exec -it "${PREFIX}_couchbase_1" triton-bootstrap bootstrap benchmark
            let COUCHBASERESPONSIVE=1
        else
            sleep 1.3
        fi
    done
}

# open the web consoles
showConsoles() {
    local CONSUL=$(getIpPort consul 8500)
    echo
    echo 'Consul is now running'
    echo "Dashboard: $CONSUL"
    command -v open >/dev/null 2>&1 && `open http://${CONSUL}/ui/`

    local CBDASHBOARD=$(getIpPort couchbase 8091)
    echo
    echo 'Couchbase cluster running and bootstrapped'
    echo "Dashboard: $CBDASHBOARD"
    echo 'The username and password are printed in earlier messages'
    command -v open >/dev/null 2>&1 && `open http://${CBDASHBOARD}/index.html#sec=servers`
}

# send a REST API call to remove a CB bucket
removeBucket() {
    curl -X DELETE -vvv http://${CBAPI}/pools/default/buckets/$1 \
         -u ${CB_USER}:${CB_PASSWORD}
}

# send a REST API call to Couchbase to create a CB bucket
createBucket() {
    docker exec -it ${PREFIX}_couchbase_1 \
           /opt/couchbase/bin/couchbase-cli bucket-create -c 127.0.0.1:8091 \
           -u ${CB_USER} -p ${CB_PASSWORD} \
           --bucket=$1 \
           --bucket-type=couchbase \
           --bucket-ramsize=${CB_RAM_QUOTA} \
           --bucket-replica=1
}

# send a REST API call to Couchbase to create a N1QL index
createIndex() {
    echo $1
    curl -s -X POST http://${N1QLAPI}/query/service \
         -u ${CB_USER}:${CB_PASSWORD} \
         -d "statement=$1"
}

# create all buckets and indexes we need. if you modify the names
# of the buckets in config.json you'll need to modify this section
setupCouchbase() {
    CBAPI=$(getIpPort couchbase 8091)
    N1QLAPI=$(getIpPort couchbase 8093)
    echo
    echo 'Creating Couchbase buckets'
    removeBucket benchmark
    createBucket users
    createBucket users_pictures
    createBucket users_publishments

    echo 'Creating Couchbase indexes'
    createIndex 'CREATE PRIMARY INDEX ON users'
    createIndex 'CREATE PRIMARY INDEX ON users_pictures'
    createIndex 'CREATE PRIMARY INDEX ON users_publishments'
}

# start up the Touchbase application and launch it in the
# browser
startApp() {
    # TODO: inject template to Consul
    ${COMPOSE} up -d touchbase
    local TB=$(getIpPort touchbase 3000)
    echo
    echo 'Opening touchbase application'
    command -v open >/dev/null 2>&1 && `open http://${TB}`
}

startNginx() {
    # TODO: inject template to Consul
    ${COMPOSE} up -d nginx
    local NGINX=$(getIpPort nginx 80)
    echo
    echo 'Opening web page'
    command -v open >/dev/null 2>&1 && `open http://${NGINX}`
}

startCloudflare() {
    ${COMPOSE} up -d cloudflare
}

# scale the entire application to 2 Nginx, 2 app servers, 3 CB nodes
scaleUp() {
    echo
    echo 'Scaling Couchbase cluster to three nodes'
    echo "${COMPOSE} scale couchbase=3"
    ${COMPOSE} scale couchbase=3
    ${COMPOSE} scale touchbase=2
    ${COMPOSE} scale nginx=2
}

while getopts "f:p:h" optchar; do
    case "${optchar}" in
        f) COMPOSE_CFG=" -f ${OPTARG}" ;;
        p) PREFIX=${OPTARG} ;;
        h) usage; exit 0;;
    esac
done
shift $(expr $OPTIND - 1 )

COMPOSE="docker-compose -p ${PREFIX}${COMPOSE_CFG:-}"
CONFIG_FILE=${COMPOSE_CFG:-docker-compose.yml}

cmd=$1
if [ ! -z "$cmd" ]; then
    shift 1
    $cmd "$@"
    exit
fi

prep
startDatabase
showConsoles
setupCouchbase
startApp
startNginx
startCloudflare
scaleUp
