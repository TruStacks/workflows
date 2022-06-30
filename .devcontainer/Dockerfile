ARG VARIANT="8.5"
FROM registry.access.redhat.com/ubi8/ubi:${VARIANT}

RUN dnf install -y \
    gzip \
    sudo \
    tar

RUN cd /usr/local && \
    curl -L https://dl.dagger.io/dagger/install.sh | sh

RUN useradd trustacks
RUN echo "trustacks ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/trustacks

USER trustacks:0