#!/bin/bash

VERSION=1.0.0
GITHUB_LINK=https://github.com/michaelweidmann/automated-neo4j-load-tester

# Prints a version message if the user requests it.
function version() {
    echo "automated-neo4j-load-tester version $VERSION"
    exit
}

# Prints the general help message how to use the program.
function help() {
    echo "Automated load tester for Neo4j. Version $VERSION."
    echo "Usage: automated-neo4j-load-tester ([<test_type> <options>] | [options])"
    echo ""
    echo "Options:"
    echo "  -h  --help             Displays this help message."
    echo "  -v  --version          Displays the version of this program."
    echo ""
    echo "Currently are three test types supported:"
    echo "  automated-neo4j-load-tester vm <options> --> Creates a VM cluster and executes tests."
    echo "  automated-neo4j-load-tester k8s <options> --> Creates a Kubernetes cluster and executes tests."
    echo "  automated-neo4j-load-tester test <options> --> Executes tests out of a VM to a given address."
    echo ""
    echo 'Alternatively you can also specify the test type with the "TEST_TYPE" environment'
    echo 'variable. "VM", "K8S" and "TEST" are allowed. This is mostly used for docker containers.'
    echo ""
    echo "To get help for the special test types, please execute the following command:"
    echo "  automated-neo4j-load-tester <test_type> --help"
    echo ""
    echo "If this help message did not help you, then please look here: $GITHUB_LINK"
    exit
}

# Prints a help message for the "VM-mode" of this program.
function vmHelp() {
    echo "Automated load tester for Neo4j. Version $VERSION."
    echo "Usage: automated-neo4j-load-tester vm <options>"
    echo ""
    echo "This test type creates a causal cluster with virtual machines. Then a worker machine is created"
    echo "and it executes test to the Neo4j installation in the VM's. After that everything is cleaned up."
    echo ""
    echo "Required options:"
    echo "  -e  --email            The E-Mail of the Google Cloud service account to get authenticated."
    echo "  -p  --project          The Google Cloud project where the tests should be executed."
    echo "  -k  --key              A base64 encoded string containing the key of a service"
    echo "                         account to authenticate against the Google API."
    echo ""
    echo "Optional options:"
    echo "  -nv --neo4j-version    The Neo4j version which should be tested. (Default: 4.0.0)"
    echo "  -cs --core-servers     The amount of core servers which should be deployed. (Default: 3)"
    echo "  -rr --read-replicas    The amount of read replica servers which should be deployed. (Default: 0)"
    echo "  -m  --machine          The type of machine which will be chosen. Please look at"
    echo "                         https://cloud.google.com/compute/docs/machine-types. (Default: n1-standard-2)"
    echo "  -dt --disk-type        The type of disk type which will be used. Please look at"
    echo "                         https://cloud.google.com/compute/docs/disks/. (Default: pd-ssd)"
    echo "  -ds --disk-size        The disk size which will be used. Please look at"
    echo "                         https://cloud.google.com/compute/docs/disks/. (Default: 64)"
    echo "  -z  --zone             The zone in which the tests are executed. Please look at"
    echo "                         https://cloud.google.com/compute/docs/regions-zones. (Default: europe-west-3-c)"
    echo "  -h  --help             Prints this help message."
    echo "  -v  --version          Prints the currently used version of this program."
    echo ""
    echo "You can also use environment variables which will be preferred."
    echo "The corresponding environment variables are:"
    echo "  EMAIL"
    echo "  PROJECT"
    echo "  KEY"
    echo "  NEO4J_VERSION"
    echo "  CORE_SERVERS"
    echo "  READ_REPLICAS"
    echo "  MACHINE"
    echo "  DISK_TYPE"
    echo "  DISK_SIZE"
    echo "  ZONE"
    echo 'The test type can be specified with the "TEST_TYPE" environment variable. "VM", "K8S" and "TEST"'
    echo "are allowed. This is mostly used for docker containers."
    echo ""
    echo "If this help message did not help you, then please look here: $GITHUB_LINK"
    exit
}

# Prints a help message for the "K8S-mode" of this program.
function k8sHelp() {
    echo "Automated load tester for Neo4j. Version $VERSION."
    echo "Usage: automated-neo4j-load-tester k8s <options>"
    echo ""
    echo "This test type creates a causal cluster in a Kubernetes cluster. Then a container is executed in"
    echo "the cluster which executes tests. After that everything is cleaned up."
    echo ""
    echo "Required options:"
    echo "  -e  --email            The E-Mail of the Google Cloud service account to get authenticated."
    echo "  -p  --project          The Google Cloud project where the tests should be executed."
    echo "  -k  --key              A base64 encoded string containing the key of a service"
    echo "                         account to authenticate against the Google API."
    echo ""
    echo "Optional options:"
    echo "  -nv --neo4j-version    The Neo4j version which should be tested. (Default: 4.0.4)"
    echo "  -cs --core-servers     The amount of core servers which should be deployed. (Default: 3)"
    echo "  -rr --read-replicas    The amount of read replica servers which should be deployed. (Default: 0)"
    echo "  -m  --machine          The type of machine which will be chosen for the Kubernetes nodes. Please look at"
    echo "                         https://cloud.google.com/compute/docs/machine-types. (Default: n1-standard-2)"
    echo "  -dt --disk-type        The type of disk type which will be used for persistent data storage. Please look at"
    echo "                         https://cloud.google.com/compute/docs/disks/. (Default: pd-ssd)"
    echo "  -ds --disk-size        The disk size which will be used. Please look at"
    echo "                         https://cloud.google.com/compute/docs/disks/. (Default: 64)"
    echo "  -z  --zone             The zone in which the tests are executed. Please look at"
    echo "                         https://cloud.google.com/compute/docs/regions-zones. (Default: europe-west-3-c)"
    echo "  -n  --nodes            The amount of Kubernetes nodes (the size of the node pool). (Default: 3)"
    echo "  -h  --help             Prints this help message."
    echo "  -v  --version          Prints the currently used version of this program."
    echo ""
    echo "You can also use environment variables which will be preferred."
    echo "The corresponding environment variables are:"
    echo "  EMAIL"
    echo "  PROJECT"
    echo "  KEY"
    echo "  NEO4J_VERSION"
    echo "  CORE_SERVERS"
    echo "  READ_REPLICAS"
    echo "  MACHINE"
    echo "  DISK_TYPE"
    echo "  DISK_SIZE"
    echo "  ZONE"
    echo "  NODES"
    echo 'The test type can be specified with the "TEST_TYPE" environment variable. "VM", "K8S" and "TEST"'
    echo "are allowed. This is mostly used for docker containers."
    echo ""
    echo "If this help message did not help you, then please look here: $GITHUB_LINK"
    exit
}

function testHelp() {
    echo "Automated load tester for Neo4j. Version $VERSION."
    echo "Usage: automated-neo4j-load-tester test <options>"
    echo ""
    echo "This test type executes a test to a already deployed Neo4j instance. It takes an Address and"
    echo "a password of the neo4j user as an argument. A virtual machine will be created which of course"
    echo "will be cleaned up."
    echo ""
    echo "Required options:"
    echo "  -e  --email            The E-Mail of the Google Cloud service account to get authenticated."
    echo "  -p  --project          The Google Cloud project where the tests should be executed."
    echo "  -k  --key              A base64 encoded string containing the key of a service"
    echo "                         account to authenticate against the Google API."
    echo "  -a  --address          An address of an existing Neo4j instance which should be tested."
    echo "  -pw --password         The password of the neo4j user to authenticate against the database."
    echo ""
    echo "Optional options:"
    echo "  -z  --zone             The zone in which the tests are executed. Please look at"
    echo "                         https://cloud.google.com/compute/docs/regions-zones. (Default: europe-west-3-c)"
    echo "  -h  --help             Prints this help message."
    echo "  -v  --version          Prints the currently used version of this program."
    echo ""
    echo "You can also use environment variables which will be preferred."
    echo "The corresponding environment variables are:"
    echo "  EMAIL"
    echo "  PROJECT"
    echo "  KEY"
    echo "  ADDRESS"
    echo "  PASSWORD"
    echo "  ZONE"
    echo 'The test type can be specified with the "TEST_TYPE" environment variable. "VM", "K8S" and "TEST"'
    echo "are allowed. This is mostly used for docker containers."
    echo ""
    echo "If this help message did not help you, then please look here: $GITHUB_LINK"
    exit
}

# Is executed if an error in the script ocurred.
function errorHandler() {
    echo "An error occurred! If it persists, please contact the developer on Github: $GITHUB_LINK"
    echo "WARNING: It is possible that some resources have been created and are still existing! They can cause costs! Please check it out."
}

# Setups the worker machine and executes tests.
# $1 --> $PROJECT
# $2 --> $ZONE
# $3 --> $ADDRESS
# $4 --> $PASSWORD
function workerMachineSetupAndRun() {
    echo "Check if worker machine exists..."

    # Checks whether the worker machine exists.
    WORKER_NAME="automated-load-test-worker"
    WORKER_MACHINE_EXISTENCE_CHECK=$(gcloud compute instances list --project $1 --zones=$2 --filter=$WORKER_NAME)

    # If the worker machine exists, it gets deleted to support the newest version of the test container and to update the IP/password parameters.
    if [[ $WORKER_MACHINE_EXISTENCE_CHECK ]]; then
        echo "Worker machine exists. It gets deleted..."

        gcloud -q compute instances delete $WORKER_NAME --zone=$2 --project=$1 > /dev/null

        echo "Successfully deleted the worker machine! Now creating a new machine."
    else
        echo "Worker machine does not exist. Creating..."
    fi

    # Create the worker machine.
    gcloud compute --project=$1 instances create-with-container $WORKER_NAME --zone=$2 \
            --container-arg="/usr/src/jmeter/bin/jmeter"  --container-arg="-n" --container-arg="-t" --container-arg="/usr/src/jmeter/testPlan.jmx" \
            --container-arg="-Jurl=$3" --container-arg="-Jpassword=$4" --container-arg="-f" --container-arg="-l" \
            --container-arg="/usr/src/jmeter/reports/results.jtl" --container-arg="-j" --container-arg="/usr/src/jmeter/reports/jmeter.log" \
            --container-arg="-e" --container-arg="-o" --container-arg="/usr/src/jmeter/reports/dashboard" --container-command="" \
            --container-image=$WORKER_IMAGE --container-stdin --container-tty \
            --container-mount-host-path=host-path=/home/neo4j-jmeter,mount-path=/usr/src/jmeter/reports --container-restart-policy never \
            --machine-type=n1-standard-16 --network-tier=PREMIUM --boot-disk-size=10GB \
            --boot-disk-type=pd-ssd --boot-disk-device-name=automated-load-test-worker-disk > /dev/null

    echo "Worker machine created!"
    echo ""
    echo "Executing tests..."

    # SSH into the worker machine.
    # Wait until the container is up and running and then attach it to view its logs.
    gcloud compute ssh --project=$1 --zone $2 --quiet user@$WORKER_NAME \
        --command='while [ -z $(docker ps -aqf name='"$WORKER_NAME"') ]; do sleep 1; done && docker ps -aqf name='"$WORKER_NAME"' | xargs -I % docker attach % --no-stdin'

    # Copy the results of the worker machine to the local system/container.
    gcloud compute scp --project=$1 user@$WORKER_NAME:/home/neo4j-jmeter ./reports --zone=$2 --quiet --recurse > /dev/null

    echo ""
    echo "Successfully executed tests - you can find the results in ./reports"
    echo ""
}
