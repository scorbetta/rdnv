FROM ubuntu:22.04

SHELL ["/bin/bash", "-c"]

# Packages
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata
RUN apt-get install -y sudo vim git cscope wget software-properties-common gzip

# KiCAD
RUN add-apt-repository -y ppa:kicad/kicad-8.0-releases
RUN apt-get update
RUN apt-get install -y kicad

# Users
RUN useradd -ms /bin/bash user
RUN usermod -aG sudo user
RUN usermod -aG users user
RUN echo "user:user" | chpasswd

# Tail stuff
USER user
WORKDIR /home/user
ENTRYPOINT ["/bin/bash"]
