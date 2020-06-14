#!/bin/bash

# Abortion on error
set -e
source util.sh

export WORKDIR=$(cd $(dirname $0) && pwd)
export WORKER_IMAGE=michaelweidmann/automated-neo4j-load-tester-worker

# Parses the arguments which were passed to the program.
function parseArguments() {
    # Iterate over every argument passed to the program
    while [ "$1" != "" ]; do
        case "$1" in
        -h | --help)
            help
            ;;
        -v | --version)
            version
            ;;
        *)
            TEST_TYPE="${TEST_TYPE:-$1}"
            break
            ;;
        esac
    done
}

# The main function of this program. Runs other shell scripts based on the type.
function run() {
    parseArguments "$@"

    if [[ $TEST_TYPE = "vm" ]] || [[ $TEST_TYPE = "VM" ]]
    then
        "$WORKDIR/commands/vm.sh" "${@:2}"
    elif [[ $TEST_TYPE = "k8s" ]] || [[ $TEST_TYPE = "K8S" ]]
    then
        "$WORKDIR/commands/k8s.sh" "${@:2}"
    elif [[ $TEST_TYPE = "test" ]] || [[ $TEST_TYPE = "TEST" ]]
    then
        "$WORKDIR/commands/test.sh" "${@:2}"
    else
        echo "Error: invalid command. Please check the help message below."
        help
    fi
}

run "$@"
