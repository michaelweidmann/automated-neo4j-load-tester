#!/bin/bash

# Abortion on error
set -e
source util.sh

NAME=neo4j-automatic-load-test-cluster

# Parses the arguments which were passed to the program.
function parseArguments() {
    # Iterate over every argument passed to the program and save it into a variable.
    while [ "$1" != "" ]; do
        case "$1" in
        -e | --email)
            EMAIL="${EMAIL:-$2}"
            shift
            ;;
        -p | --project)
            PROJECT="${PROJECT:-$2}"
            shift
            ;;
        -k | --key)
            KEY="${KEY:-$2}"
            shift
            ;;
        -nv | --neo4j-version)
            NEO4J_VERSION="${NEO4J_VERSION:-$2}"
            shift
            ;;
        -cs | --core-servers)
            CORE_SERVERS="${CORE_SERVERS:-$2}"
            shift
            ;;
        -rr | --read-replicas)
            READ_REPLICAS="${READ_REPLICAS:-$2}"
            shift
            ;;
        -m | --machine)
            MACHINE="${MACHINE:-$2}"
            shift
            ;;
        -dt | --disk-type)
            DISK_TYPE="${DISK_TYPE:-$2}"
            shift
            ;;
        -ds | --disk-size)
            DISK_SIZE="${DISK_SIZE:-$2}"
            shift
            ;;
        -z | --zone)
            ZONE="${ZONE:-$2}"
            shift
            ;;
        -h | --help)
            vmHelp
            ;;
        -v | --version)
            version
            ;;
        *)
            echo "Error: invalid command. Please check the help message below."
            vmHelp
            ;;
        esac
        shift
    done

    # Default values for the variables.
    NEO4J_VERSION="${NEO4J_VERSION:-4.0.0}"
    CORE_SERVERS="${CORE_SERVERS:-3}"
    READ_REPLICAS="${READ_REPLICAS:-0}"
    MACHINE="${MACHINE:-n1-standard-2}"
    DISK_TYPE="${DISK_TYPE:-pd-ssd}"
    DISK_SIZE="${DISK_SIZE:-64}"
    ZONE="${ZONE:-europe-west3-c}"

    # Check if the required arguments were given.
    if [[ -z $EMAIL || -z $PROJECT || -z $KEY ]]; then
        echo "Error: invalid command. Please check the help message below."
        vmHelp
    fi

    # Decode the base 64 encoded service account key.
    echo $KEY | base64 --decode > key.json
}

# Checks whether a correct Neo4j version is used.
function checkVersion() {
    result=$(curl --output /dev/null --silent --fail -r 0-0 "$1")

    if ! $result; then
        echo "Error: An unsupported Neo4j version was chosen. These are the only supported versions:"
        echo "  - 3.5.3"
        echo "  - 3.5.7"
        echo "  - 3.5.8"
        echo "  - 3.5.5"
        echo "  - 3.5.14"
        echo "  - 3.5.16"
        echo "  - 4.0.0"
        echo "  - 4.0.2"
        echo "  - 4.0.3"
        exit
    fi
}

# Creates the cluster if it does not exist.
# If it exists then the IP and Password is parsed.
function clusterSetup() {
    echo "Check if cluster exists..."

    CLUSTER_EXISTENCE_CHECK=$(gcloud deployment-manager --project $PROJECT deployments list --simple-list --filter=$NAME)

    if [[ $CLUSTER_EXISTENCE_CHECK ]]; then
        echo "Cluster exists!"
    else
        echo "Cluster does not exist. Creating the cluster..."

        # Creating the cluster with the deployment manager.
        gcloud deployment-manager deployments create $NAME \
            --project $PROJECT \
            --template "$TEMPLATE_URL" \
            --properties "zone:'$ZONE',clusterNodes:'$CORE_SERVERS',readReplicas:'$READ_REPLICAS',bootDiskSizeGb:$DISK_SIZE,bootDiskType:'$DISK_TYPE',machineType:'$MACHINE'" > /dev/null
        echo "Cluster successfully created!"
    fi

    # Get information about the cluster and parse useful information of it.
    OUTPUT=$(gcloud deployment-manager --project $PROJECT deployments describe $NAME)

    PASSWORD=$(echo $OUTPUT | perl -ne 'm/password\s+([^\s]+)/; print $1;')
    IP=$(echo $OUTPUT | perl -ne 'm/vm1URL\s+https:\/\/([^\s]+):/; print $1;')

    echo ""
}

# Cleanup: Deletes the worker machine and the created cluster. Also removes the service account key.
function cleanup() {
    echo "Delete the worker machine and the cluster..."

    gcloud -q compute instances delete $WORKER_NAME --zone=$ZONE --project=$PROJECT > /dev/null
    gcloud -q deployment-manager deployments delete $NAME --project $PROJECT > /dev/null
    gcloud -q compute disks delete $(gcloud compute disks list --project $PROJECT --filter="name~'$NAME'" --uri) > /dev/null

    echo "Successfully cleaned up..."
    echo ""

    rm -f key.json
}

# The "main" function of the VM test.
function run() {
    parseArguments "$@"

    echo "Logging into your service account..."
    gcloud auth activate-service-account $EMAIL --key-file key.json --quiet > /dev/null
    echo "Successfully logged in!"
    echo ""

    TEMPLATE_URL=https://storage.googleapis.com/neo4j-deploy/$NEO4J_VERSION/causal-cluster/neo4j-causal-cluster.jinja
    checkVersion "$TEMPLATE_URL"

    clusterSetup
    workerMachineSetupAndRun $PROJECT $ZONE "neo4j://${IP}:7687" $PASSWORD
    cleanup

    echo "Important: If a SSH key was generated, an entry in the Compute Engine metadata was done."
    echo "You can remove the metadata here (https://console.cloud.google.com/compute/metadata)"
}

trap 'errorHandler' ERR
run "$@"
