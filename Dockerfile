FROM ubuntu
RUN apt-get update && \
      apt-get -y install sudo

RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo


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
RUN apt-get install iputils-ping -y
RUN apt-get install dmidecode -y
RUN apt-get install net-tools -y

RUN node --version
RUN npm install -g json
LABEL maintainer "Hainaku CORPORATION <djhainakosurge@gmail.com>"
RUN apt-get install -y build-essential


RUN mkdir -p /home/minerstat/minerstat-os

COPY . /home/minerstat/minerstat-os/
WORKDIR /home/minerstat/minerstat-os/
RUN mkdir -p /media/storage/
RUN cp config.js /media/storage/
RUN chmod +x cronjob.sh
RUN chmod +x core/init.sh
RUN chmod +x launcher.sh
#CMD ./cronjob.sh 2022-01-01 2023-01-23
USER docker
#RUN  timeout 20 nvidia-settings -a GPUPowerMizerMode=1 -c :0 2>/dev/null
RUN ./core/nvidia-update --install 525.60.11

CMD node --max-old-space-size=128 start

