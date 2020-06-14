#!/bin/bash

# Abortion on error
set -e
source util.sh

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
        -a | --address)
            ADDRESS="${ADDRESS:-$2}"
            shift
            ;;
        -pw | --password)
            PASSWORD="${PASSWORD:-$2}"
            shift
            ;;
        -z | --zone)
            ZONE="${ZONE:-$2}"
            shift
            ;;
        -h | --help)
            testHelp
            ;;
        -v | --version)
            version
            ;;
        *)
            echo "Error: invalid command. Please check the help message below."
            testHelp
            ;;
        esac
        shift
    done

    ZONE="${ZONE:-europe-west3-c}"

    # Check if the required arguments were given.
    if [[ -z $EMAIL || -z $PROJECT || -z $KEY || -z $ADDRESS || -z $PASSWORD ]]; then
        echo "Error: invalid command. Please check the help message below."
        testHelp
    fi

    # Decode the base 64 encoded service account key.
    echo $KEY | base64 --decode > key.json
}

# Cleanup: Deletes the worker machine. Also removes the service account key.
function cleanup() {
    echo "Delete the worker machine..."

    gcloud -q compute instances delete $WORKER_NAME --zone=$ZONE --project=$PROJECT > /dev/null

    echo "Successfully cleaned up..."
    echo ""

    rm -f key.json
}

# The "main" function of the test tool.
function run() {
    parseArguments "$@"

    echo "Logging into your service account..."
    gcloud auth activate-service-account $EMAIL --key-file key.json --quiet > /dev/null
    echo "Successfully logged in!"
    echo ""

    workerMachineSetupAndRun $PROJECT $ZONE $ADDRESS $PASSWORD
    cleanup

    echo "Important: If a SSH key was generated, an entry in the Compute Engine metadata was done."
    echo "You can remove the metadata here (https://console.cloud.google.com/compute/metadata)"
}

trap 'errorHandler' ERR
run "$@"
