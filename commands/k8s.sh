#!/bin/bash

# Abortion on error
set -e
source util.sh

NAME=neo4j-automatic-load-test-cluster
declare -A helm

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
        -cs | --core-servers)
            CORE_SERVERS="${CORE_SERVERS:-$2}"
            shift
            ;;
        -rr | --read-replicas)
            READ_REPLICAS="${READ_REPLICAS:-$2}"
            shift
            ;;
        -z | --zone)
            ZONE="${ZONE:-$2}"
            shift
            ;;
        -nv | --neo4j-version)
            NEO4J_VERSION="${NEO4J_VERSION:-$2}"
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
        -n | --nodes)
            NODES="${NODES:-$2}"
            shift
            ;;
        -h | --help)
            k8sHelp
            ;;
        -v | --version)
            version
            ;;
        *)
            echo "Error: invalid command. Please check the help message below."
            k8sHelp
            ;;
        esac
        shift
    done

    NEO4J_VERSION="${NEO4J_VERSION:-4.0.4}"
    ZONE="${ZONE:-europe-west3-c}"
    MACHINE="${MACHINE:-n1-standard-2}"
    DISK_TYPE="${DISK_TYPE:-pd-ssd}"
    DISK_SIZE="${DISK_SIZE:-64}"
    NODES="${NODES:-3}"
    CORE_SERVERS="${CORE_SERVERS:-3}"
    READ_REPLICAS="${READ_REPLICAS:-0}"

    # Check if the required arguments were given.
    if [[ -z $EMAIL || -z $PROJECT || -z $KEY ]]; then
        echo "Error: invalid command. Please check the help message below."
        k8sHelp
    fi

    # Decode the base 64 encoded service account key.
    echo $KEY | base64 --decode > key.json
}

# Initializes a map with every Neo4j version existing in the helm repo or the self hosted repo (https://github.com/neo4j-contrib/neo4j-helm).
function initializeVersionMap() {
    helm[3.2.3]="stable/neo4j --version 0.7.1"
    helm[3.3.4]="stable/neo4j --version 0.7.3"
    helm[3.4.5]="stable/neo4j --version 2.0.0"
    helm[4.0.3]="stable/neo4j --version 3.0.0"
    helm[4.0.4]="stable/neo4j --version 3.0.1"
    helm[4.0.4-2]="https://github.com/neo4j-contrib/neo4j-helm/releases/download/4.0.4-2/neo4j-4.0.4-2.tgz"
}

# Checks whether a correct Neo4j version is used.
function checkVersion() {
    MAP_OUTPUT=${helm[$NEO4J_VERSION]}

    if [[ -z $MAP_OUTPUT ]]; then
        echo "Error: An unsupported Neo4j version was chosen. These are the only supported versions:"
        echo "  - 3.2.3"
        echo "  - 3.3.4"
        echo "  - 3.4.5"
        echo "  - 4.0.3"
        echo "  - 4.0.4"
        echo "  - 4.0.4-2"
        exit
    fi
}

# Creates the kubernetes cluster if it does not exist.
function clusterSetup() {
    echo "Check if cluster exists..."

    # Checks if the cluster exists.
    CLUSTER_EXISTENCE_CHECK=$(gcloud container --project $PROJECT clusters list --filter=$NAME --zone $ZONE)

    if [[ $CLUSTER_EXISTENCE_CHECK ]]; then
        echo "Cluster exists!"
    else
        echo "Cluster does not exist. Creating the cluster..."

        gcloud container --project $PROJECT clusters create $NAME --zone $ZONE --no-enable-basic-auth \
            --machine-type $MACHINE --disk-type $DISK_TYPE --disk-size $DISK_SIZE \
            --num-nodes $NODES --enable-stackdriver-kubernetes --enable-ip-alias \
            --default-max-pods-per-node "110" --no-enable-master-authorized-networks \
            --addons HttpLoadBalancing --no-enable-autoupgrade --enable-autorepair > /dev/null

        echo "Cluster successfully created!"
    fi

    # Generate kubeconfig.
    gcloud container clusters get-credentials --project $PROJECT --zone $ZONE $NAME > /dev/null

    # Add the helm repo to the cluster.
    helm repo add stable https://kubernetes-charts.storage.googleapis.com > /dev/null

    echo ""
    echo "Check if Neo4j is deployed..."

    # Checks if a Neo4j cluster exists.
    NEO4j_EXISTENCE_CHECK=$(helm list --filter="$NAME" -q)

    if [[ $NEO4j_EXISTENCE_CHECK ]]; then
        echo "Neo4j is deployed!"
    else
        echo "Neo4j is not deployed. Creating..."

        # Install the helm chart on the kubernetes cluster.
        helm install $NAME ${helm[$NEO4J_VERSION]} --set core.numberOfServers=$CORE_SERVERS \
            --set readReplica.numberOfServers=$READ_REPLICAS \
            --set acceptLicenseAgreement=yes --wait > /dev/null

        echo "Neo4j successfully deployed!"
    fi

    echo ""

    NAMESPACE=$(helm status $NAME | grep NAMESPACE | sed -e 's/.*: //g')
    ADDRESS="${NAME}-neo4j.${NAMESPACE}.svc.cluster.local"
    PASSWORD=$(kubectl get secrets $NAME-neo4j-secrets -o yaml | grep password | sed 's/.*: //' | base64 -d)
}

# Setups the worker environment if necessary and executing tests.
function workerSetupAndRun() {
    WORKER_NAME="automated-load-test-worker"

    echo "Configuring the worker node pool..."
    NODE_POOL_EXISTENCE_CHECK=$(gcloud container node-pools list --cluster $NAME --zone $ZONE --project $PROJECT --filter=worker-pool)

    if [[ ! $NODE_POOL_EXISTENCE_CHECK ]]; then
        gcloud container node-pools create worker-pool --cluster $NAME \
            --machine-type=n1-standard-16 --num-nodes=1 \
            --project=$PROJECT --zone=$ZONE > /dev/null
    fi

    echo ""
    echo "Executing tests..."

    kubectl run $WORKER_NAME \
        --image=$WORKER_IMAGE \
        --restart=Never --labels="cloud.google.com/gke-nodepool=worker-pool" \
        --command -- tail -f /dev/null > /dev/null

    kubectl wait --for=condition=Ready pod/$WORKER_NAME > /dev/null
    kubectl exec -it $WORKER_NAME -- /usr/src/jmeter/bin/jmeter -n -t /usr/src/jmeter/testPlan.jmx -Jurl=neo4j://$ADDRESS -Jpassword=$PASSWORD -f -l /usr/src/jmeter/reports/results.jtl -e -o /usr/src/jmeter/reports/dashboard
    kubectl cp $WORKER_NAME:/usr/src/jmeter/reports ./reports > /dev/null

    echo ""
    echo "Successfully executed tests - you can find the results in ./reports"
    echo ""

    kubectl delete pod $WORKER_NAME > /dev/null
}

# Cleanup: Deletes the whole cluster and the service account key.
function cleanup() {
    echo "Delete the Kubernetes cluster..."

    gcloud -q container clusters delete $NAME --project=$PROJECT --zone $ZONE > /dev/null

    echo "Successfully cleaned up..."
    echo ""

    rm -f key.json
}

# The "main" function of the K8s test.
function run() {
    parseArguments "$@"

    echo "Logging into your service account..."
    gcloud auth activate-service-account $EMAIL --key-file key.json > /dev/null
    echo "Successfully logged in!"
    echo ""

    initializeVersionMap
    checkVersion

    clusterSetup
    workerSetupAndRun

    cleanup

    echo "Important: If a kubeconfig was generated be careful with it!"
}

trap 'errorHandler' ERR
run "$@"
