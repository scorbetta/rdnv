FROM scorbetta/rdnv-docker:modelsim

SHELL ["/bin/bash", "-c"]

# Additional simulators
USER root
RUN apt-get update
RUN apt-get install -y verilator iverilog

# Additional packages
RUN apt-get install -y cscope gtkwave

USER user
WORKDIR /home/user

ENTRYPOINT ["/bin/bash"]
