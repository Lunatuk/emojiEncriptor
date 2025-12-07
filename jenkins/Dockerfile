FROM jenkins/jenkins:lts-jdk17

USER root

RUN apt-get update && \
    apt-get install -y golang-go docker.io docker-compose && \
    rm -rf /var/lib/apt/lists/*

ENV GOPATH=/go
ENV PATH=$PATH:/usr/lib/go/bin:/go/bin

