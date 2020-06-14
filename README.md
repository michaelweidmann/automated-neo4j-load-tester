# Automated Neo4j Load Tester
**Important:** Only Unix machines (for native use of the tool) and machines where Docker is installed are supported.

This project aims to make load and performance tests on the Neo4j database as simple and automated as possible.
The Google Cloud is used as execution environment.
If you have any questions regarding this project, do not hesitate to raise an issue!

## Getting started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

Make sure you have installed all of the following prerequisites on your development machine:

* Git - [Download & Install Git](https://git-scm.com/downloads). OSX and Linux machines typically have this already installed.
* Kubectl - [Download & Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/). Needed to interact with a Kubernetes cluster.
* Helm - [Download & Install Helm](https://helm.sh/docs/intro/install/). Needed to deploy easily applications to a Kubernetes cluster.
* GCloud SDK - [Download & Install GCloud](https://cloud.google.com/sdk/install). Commandline tool to easily interact with the Google Cloud API. Python is required for this tool.
* (Optionally) Docker - [Download & Install Docker](https://docs.docker.com/get-docker/). Needed if a non-Unix machine is used. Otherwise optional.

### How to use it

There are general two ways to use this application:
1. With Docker in a container
2. Natively on your machine

All approaches are described now.

#### Usage with Docker

Just execute these simple steps:

```bash
docker pull michaelweidmann/automated-neo4j-load-tester
docker run --rm -it --name automated-neo4j-load-tester -e TEST_TYPE=<TEST_TYPE> -e KEY=<KEY> -e EMAIL=<EMAIL> -e PROJECT=<PROJECT> michaelweidmann/automated-neo4j-load-tester
```

How to use it exactly and what for options you have you can read in the [manual](#manual).

#### Native usage

First you need to clone this repository:

```bash
git clone https://github.com/michaelweidmann/automated-neo4j-load-tester.git
cd automated-neo4j-load-tester
```

Now you can already start!

```bash
./automated-neo4j-load-tester.sh
```

A help message should be printed.
How to use it exactly and what for options you have you can read in the [manual](#manual).

### Manual

This tool contains three test types.
If this tool is used natively then you can specify the test type as follows:

```bash
./automated-neo4j-load-tester.sh <TEST_TYPE>
```

`<TEST_TYPE>` can be replaced with `vm`, `k8s` or `test`.

If docker is used you need to use an environment variable:

```bash
docker run --rm -it --name automated-neo4j-load-tester -e TEST_TYPE=<TEST_TYPE> michaelweidmann/automated-neo4j-load-tester
```

`<TEST_TYPE>` can be replaced with `VM`, `K8S` or `TEST`.

**Important:** Environment variables are treated preferentially.

The `VM` test describes a test where Neo4j is deployed in a causal cluster in virtual machines.
After that a worker machine is created and executes tests against this instance.
Finally everything is removed.

The `K8S` test describes a test where Neo4j is deployed in a Kubernetes cluster.
After that a new worker node pool is created and a pod is deployed.
This pod runs tests against the Neo4j instance.
Finally everything is removed.

The `TEST` test runs a performance test on a Neo4j instance which is already running.
A virtual machine will be deployed which executes the test.
An address and a password needs to be passed to this mode to connect to the database.
After execution the worker machine is deleted not the cluster!

#### Required options for every test type
| Option              | Environment Variable | Required?          | Default | Description                                                                                                                                                                 |
| ------------------- | -------------------- | ------------------ | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--email` or `-e`   | `EMAIL`              | :heavy_check_mark: | None    | The E-Mail address of the Google Cloud Account. Typically this E-Mail address should be a Service Account Address.                                                          |
| `--project` or `-p` | `PROJECT`            | :heavy_check_mark: | None    | The Google Cloud Project in which the test environment is deployed and executed.                                                                                            |
| `--key` or `-k`     | `KEY`                | :heavy_check_mark: | None    | The Base64 encoded Service Account key. You can encode it and export it directly with this command `export KEY=$(base64 ../key.json -w 0)`. Now you can use it with `$KEY`. |

#### VM Options
| Option                     | Environment Variable | Required? | Default        | Description                                                                                                                                |
| -------------------------- | -------------------- | --------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `--neo4j-version` or `-nv` | `NEO4J_VERSION`      | :x:       | 4.0.0          | The Neo4j version which should be tested.                                                                                                  |
| `--core-servers` or `-cs`  | `CORE_SERVERS`       | :x:       | 3              | The amount of core servers which should be deployed.                                                                                       |
| `--read-replicas` or `-rr` | `READ_REPLICAS`      | :x:       | 0              | The amount of read replica servers which should be deployed.                                                                               |
| `--machine` or `-m`        | `MACHINE`            | :x:       | n1-standard-2  | The type of machine which will be chosen. Please look [here](https://cloud.google.com/compute/docs/machine-types) for further information. |
| `--disk-type` or `-dt`     | `DISK_TYPE`          | :x:       | pd-ssd         | The type of disk type which will be used. Please look [here](https://cloud.google.com/compute/docs/disks/) for further information.        |
| `--disk-size` or `-ds`     | `DISK_SIZE`          | :x:       | 64             | The disk size which will be used. Please look [here](https://cloud.google.com/compute/docs/disks/) for further information.                |
| `--zone` or `-rr`          | `ZONE`               | :x:       | europe-west3-c | The zone in which the tests are executed. Please look [here](https://cloud.google.com/compute/docs/regions-zones) for further information. |

#### K8S Options
The Kubernetes test contains one more option than the VM test.

| Option                     | Environment Variable | Required? | Default        | Description                                                                                                                                |
| -------------------------- | -------------------- | --------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `--neo4j-version` or `-nv` | `NEO4J_VERSION`      | :x:       | 4.0.4          | The Neo4j version which should be tested.                                                                                                  |
| `--core-servers` or `-cs`  | `CORE_SERVERS`       | :x:       | 3              | The amount of core servers which should be deployed.                                                                                       |
| `--read-replicas` or `-rr` | `READ_REPLICAS`      | :x:       | 0              | The amount of read replica servers which should be deployed.                                                                               |
| `--machine` or `-m`        | `MACHINE`            | :x:       | n1-standard-2  | The type of machine which will be chosen. Please look [here](https://cloud.google.com/compute/docs/machine-types) for further information. |
| `--disk-type` or `-dt`     | `DISK_TYPE`          | :x:       | pd-ssd         | The type of disk type which will be used. Please look [here](https://cloud.google.com/compute/docs/disks/) for further information.        |
| `--disk-size` or `-ds`     | `DISK_SIZE`          | :x:       | 64             | The disk size which will be used. Please look [here](https://cloud.google.com/compute/docs/disks/) for further information.                |
| `--zone` or `-rr`          | `ZONE`               | :x:       | europe-west3-c | The zone in which the tests are executed. Please look [here](https://cloud.google.com/compute/docs/regions-zones) for further information. |
| `--nodes` or `-n`          | `NODES`              | :x:       | 3              | The amount of Kubernetes nodes (the size of the node pool).                                                                                |

#### Test Options
| Option                     | Environment Variable | Required? | Default        | Description                                                                                                                                |
| -------------------------- | -------------------- | --------- | -------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `--address` or `-a` | `ADDRESS`      | :heavy_check_mark:       | None | An address of an existing Neo4j instance which should be tested. |
| `--password` or `-pw`  | `PASSWORD`       | :heavy_check_mark:       | None              | The password of the neo4j user to authenticate against the database.                                                                                       |
| `--zone` or `-rr`          | `ZONE`               | :x:       | europe-west3-c | The zone in which the tests are executed. Please look [here](https://cloud.google.com/compute/docs/regions-zones) for further information. |

## Project structure
```
.
+-- commands                        --> Directory containing the subcommands.
|   +-- k8s.sh                      --> Logic for the k8s test.
|   +-- test.sh                     --> Logic for the test command.
|   +-- vm.sh                       --> Logic for the VM test.
+-- docker-jmeter                   --> Directory containing all files to dockerize JMeter.
|   +-- assets                      --> Assets which are copied into the Docker image.
|   |   +-- data.csv                --> The dataset used for the test.
|   |   +-- testPlan.jmx            --> The JMeter load test definition file.
|   +-- Dockerfile                  --> Dockerfile to dockerize JMeter.
+-- automated-neo4j-load-tester.sh  --> The main entry point of the tool.
+-- Dockerfile                      --> Dockerfile to containerize this application.
+-- util.sh                         --> Util functions for general use.
```

## TODO's
- Change JMeter's Dockerfile when the new patch is released
- Maybe a nice deep dive introduction to the Cloud architecture?
- Add a contributing guideline, pull request and issue template.

## Feature ideas
- Develop a distributed JMeter test as described in [this](https://jmeter.apache.org/usermanual/remote-test.html) article
- Develop different dataset modes
- Automatic deployment of the dashboard
