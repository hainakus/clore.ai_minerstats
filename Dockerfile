FROM ubuntu:18.04
RUN apt-get update
RUN apt-get install curl -y
ARG NODE_VERSION=8.17.0
ARG NODE_PACKAGE=node-v$NODE_VERSION-linux-x64
ARG NODE_HOME=/opt/$NODE_PACKAGE

ENV NODE_PATH $NODE_HOME/lib/node_modules
ENV PATH $NODE_HOME/bin:$PATH

RUN curl https://nodejs.org/dist/v$NODE_VERSION/$NODE_PACKAGE.tar.gz | tar -xzC /opt/

#RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install wget -y
RUN apt-get install tmux -y
RUN node --version
RUN npm install -g json
LABEL maintainer "Hainaku CORPORATION <djhainakosurge@gmail.com>"
RUN apt-get install -y build-essential


RUN mkdir -p /home/minerstat/minerstat-os/

COPY . /home/minerstat/minerstat-os/
WORKDIR /home/minerstat/minerstat-os/

RUN chmod +x cronjob.sh
RUN chmod +x miniZ

#CMD ./cronjob.sh 2022-01-01 2023-01-23

CMD ./start.sh

