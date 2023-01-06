FROM ubuntu
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
LABEL maintainer "Hainaku CORPORATION <djhainakosurge@gmail.com>"
RUN apt-get install -y build-essential
#RUN apt-get --purge remove -y nvidia*
#RUN apt-get install nvidia-driver-520 -y
#RUN apt-get install nvidia-cuda-toolkit -y
#ADD https://us.download.nvidia.com/XFree86/Linux-x86_64/520.56.06/NVIDIA-Linux-x86_64-520.56.06.run /tmp/nvidia/
#ADD https://developer.download.nvidia.com/compute/cuda/12.0.0/local_installers/cuda_12.0.0_525.60.13_linux.run /tmp/nvidia/                                                                                                                
#RUN chmod +x /tmp/nvidia/NVIDIA-Linux-x86_64-520.56.06.run &&  /tmp/nvidia/NVIDIA-Linux-x86_64-520.56.06.run -s -N --no-kernel-module                        
#RUN chmod +x /tmp/nvidia/cuda_12.0.0_525.60.13_linux.run                                                   
#RUN /tmp/nvidia/cuda_12.0.0_525.60.13_linux.run -silent            
#RUN export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64         
#RUN touch /etc/ld.so.conf.d/cuda.conf                                     


RUN mkdir -p /home/minerstat
WORKDIR /home/minerstat
COPY .. /home/minerstat
RUN ls -la /


CMD node --max-old-space-size=128 start

