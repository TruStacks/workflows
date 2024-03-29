FROM registry.access.redhat.com/ubi8/ubi-minimal

RUN microdnf install \
    findutils \
    git \
    gzip \
    tar

# install dagger
RUN cd /usr/local && \
    curl -L https://dl.dagger.io/dagger/install.sh | DAGGER_VERSION=0.2.30 sh

# install docker cli
RUN curl -Lo /tmp/docker.tgz https://download.docker.com/linux/static/stable/x86_64/docker-20.10.17.tgz && \
    cd /tmp/ && tar xvf docker.tgz && \
    install /tmp/docker/docker /usr/local/bin/docker && \
    rm -rf /tmp/docker*

# create default artifacts and mount directories
RUN mkdir /artifacts && mkdir -p /mnt/vars && mkdir -p /mnt/secrets

COPY workflows /opt/workflows
COPY docker-entrypoint /usr/local/bin/docker-entrypoint
ENTRYPOINT ["docker-entrypoint"]
