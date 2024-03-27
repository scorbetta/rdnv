FROM ubuntu:16.04

# Add 32-bit architecture version
RUN dpkg --add-architecture i386
RUN apt-get update
RUN apt-get install -y libxext6:i386 libsm6:i386 libxi-dev:i386 libxrandr-dev:i386 libxcursor-dev:i386 libxinerama-dev:i386 libfreetype6:i386 libfontconfig:i386 libglib2.0-0:i386 libstdc++6:i386

# Install user packages
RUN apt-get install -y sudo unzip vim

# udev
RUN mkdir -p /etc/udev/rules.d
#RUN echo "SUBSYSTEM==\"net\", ACTION==\"add\", ATTR{address}==\"90:1b:0e:8b:a8:2e\", NAME=\"eth0\"" >> /etc/udev/rules.d/10-net-naming.rules

# User
RUN useradd -ms /bin/bash user
RUN usermod -aG sudo user
RUN usermod -aG users user
RUN echo "user:user" | chpasswd
#COPY icecube_installer /home/user
#COPY license.dat /home/user

# Init
USER user
WORKDIR /home/user

ENTRYPOINT ["/bin/bash"]
