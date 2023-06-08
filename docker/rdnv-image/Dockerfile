# Base image
FROM ubuntu:22.04
SHELL ["/bin/bash", "-c"]

# Setup system with new user
RUN echo 'root:root' |chpasswd
RUN useradd -rm -d /home/scorbetta -s /bin/bash -u 1000 scorbetta
RUN usermod -aG sudo scorbetta
RUN echo "scorbetta:scorbetta" | chpasswd

# Update repositories and install packages
RUN apt-get update
#    GCC and Software compilation essentials
RUN apt-get install -y gcc g++ automake build-essential vim cscope bison flex
#    Python
RUN apt-get install -y python3 python3-pip
#    Icarus Verilog
RUN apt-get install -y iverilog
#    git
RUN apt-get install -y git
#    Miscellanea
RUN apt-get install -y sudo iproute2 curl openssh-client

# Switch to and setup system for new user
USER scorbetta
WORKDIR /home/scorbetta
RUN git config --global user.name "Simone Corbetta"
RUN git config --global user.email "simone.corbetta@gmail.com"
RUN git config --global core.editor "vim"
RUN mkdir ~/.ssh
RUN ssh-keyscan -H bitbucket.org >> ~/.ssh/known_hosts
RUN echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCfdqPB5cbZ9qyFr86AxEcFaPg2i6ThaOF8iV/NPI/1rZFz0Szc8zRYkVxQxF/n4uu4vRdaOo5gJMBhUESH8VDBdeSL1CqHmBWEWCKhK0wfPiWUCKI7nwp3er0aDoZjqdamzFtlkIsEOV1d8HI95TVj2USNIqrxv4xBlNkjfihPk6X/ME6CLsKEaT7X+b/WgT6h40fD/nRZe5e5tmpsvvFF/FxdepudhehtFNMMP8z0rVwgqu2JrLH7MQA+5I+0S//vTS2aYk7UIazuk2dui4o2XYeJSjThJ+qKeQDCviHOzM3mU+WtiWu53CngK5dRsgZkk1mvSsQNfPB27srxBK6V scorbetta@b79f28cc701c" > ~/.ssh/id_rsa.pub
RUN echo -e "-----BEGIN OPENSSH PRIVATE KEY-----\nb3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAABFwAAAAdzc2gtcn\nNhAAAAAwEAAQAAAQEAn3ajweXG2fasha/OgMRHBWj4Nouk4WjhfIlfzTyP9a2Rc9Es3PM0\nWJFcUMRf5+LruL0XWjqOYCTAYVBEh/FQwXXki9Qqh5gVhFgioStMHz4llAiiO58Kd3q9Gg\n6GY6nWpsxbZZCLBDldXfByPeU1Y9lEjSKq8b+MQZTZI34oT5Ol/zBOgi7ChGk+1/m/1oE+\noeNHw/50WXuXubZqbL7xRfxcXXqbnYXobRTTDD/M9K1cIKrtiayx+zEAPuSPtEv/700tmm\nJO1CGs7pNnbouKNl2HiUo04SfqinkAwr4hzszN5lPlrYlrudwp4CuXUbIGZJNZr0rEDXzw\ndu7K8QSulQAAA9Clow+SpaMPkgAAAAdzc2gtcnNhAAABAQCfdqPB5cbZ9qyFr86AxEcFaP\ng2i6ThaOF8iV/NPI/1rZFz0Szc8zRYkVxQxF/n4uu4vRdaOo5gJMBhUESH8VDBdeSL1CqH\nmBWEWCKhK0wfPiWUCKI7nwp3er0aDoZjqdamzFtlkIsEOV1d8HI95TVj2USNIqrxv4xBlN\nkjfihPk6X/ME6CLsKEaT7X+b/WgT6h40fD/nRZe5e5tmpsvvFF/FxdepudhehtFNMMP8z0\nrVwgqu2JrLH7MQA+5I+0S//vTS2aYk7UIazuk2dui4o2XYeJSjThJ+qKeQDCviHOzM3mU+\nWtiWu53CngK5dRsgZkk1mvSsQNfPB27srxBK6VAAAAAwEAAQAAAQBJ2rfTaOllL8MNk7Qv\nnThLgCddk+WEZH/ynulY89C093NjUaDWoGlBD+nSmnDUxBtqj2FOb8pbKwpSx8tFrvU49L\nIqNNSRwlVM20kGnjf+TFk5K5p/xJQjbBxDAjEp3ZJF5GX8LyrDhRICHQe8NPk6SnleaI0F\ntDJweVDsCFUBLWSpkE21QHfgR5mSeVOrRfMSjO0YK5yqdkbDbpPV2hn+C7Y9Tu/4LDOEb6\nOn5kCRgXf1W0ViTkm5IrU8GJVsmE86bYSUWyeI78okxTTKQlJYHpFcV6xtJFDIyRBqEPAz\n8VN00OVuIggRjgeRV2O3/BCxIVVwO9H9xpCFe76BQgTtAAAAgQCOG8E5zDL8Fhc5Qcsezq\nr2UYXPcjT+3Qw2+KNalt70CkTxyRPqGFVe4483BTkSjgyBuIAojuD36wLWiFsZD0EwOS/F\nxUmdpCjoPkZelzJMHffooNNWLZSlYan7OhDo6Mm8yrUFr9xnJQIWDqoXrZzEJFYC33nGBl\n8JDZ0YhcXnxgAAAIEA0j8dfX8BW1FFVDfvvphvlLoMbI31o7ZuqhcK+gdq8Psr1uGKeFHN\n3kXXmssIkhYot7Hj5h0BA33IAfAQ1bJGGHRio8oGkltZS7y/AVGeYrx/A8HwYBtemlrdvg\nsxo/oHfCKcDsDOopcndLwsFnMqkMw9z102RYFb+0JOTu9eX6sAAACBAMIqYrGF9HR+eDds\n5UXu3h66/scg8XiGfBZzUVxV/tfqwLJYS0hjUxG/PK3fPwCTJpkoZsXchr1yybiK8mFQQG\nNArk93yScRzLshjq+2oNq0iZilOe1KxNXZPh8KKGKQkXi+5jdvkFXPsDPm4o6dGWn/HJ0k\nBxld8oi50wNde+q/AAAAFnNjb3JiZXR0YUBiNzlmMjhjYzcwMWMBAgME\n-----END OPENSSH PRIVATE KEY-----\n" > ~/.ssh/id_rsa
RUN chmod 600 ~/.ssh/id_rsa

# Setup configuration from own repositories
RUN --mount=type=ssh git clone git@bitbucket.org:scorbetta/linux-cfg.git
RUN cd linux-cfg && source deployme.sourceme && cd ~

# Run shell
CMD ["/bin/bash"]
