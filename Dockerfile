FROM google/cloud-sdk:slim

RUN apt-get update && apt-get install -y apt-transport-https && \
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && \
    apt-get install -y kubectl

RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh

RUN mkdir /usr/src/automated-neo4j-load-tester

WORKDIR /usr/src/automated-neo4j-load-tester

COPY commands commands
COPY automated-neo4j-load-tester.sh .
COPY util.sh .

ENTRYPOINT ["./automated-neo4j-load-tester.sh"]
