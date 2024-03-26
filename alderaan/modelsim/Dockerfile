FROM i686/ubuntu

SHELL ["/bin/bash", "-c"]

# Packages
RUN apt-get update
RUN apt-get install -y build-essential gcc-multilib g++-multilib libc6 libncurses5 libncurses5-dev libxft2 libxft2 libxext6 libxext6 libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev llvm libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl
RUN apt-get install -y sudo vim git cscope wget autotools-dev autoconf make curl

# Users
RUN useradd -ms /bin/bash user
RUN usermod -aG sudo user
RUN usermod -aG users user
RUN echo "user:user" | chpasswd

# Modelsim
WORKDIR /tmp
RUN wget https://download.altera.com/akdlm/software/acdsinst/20.1std.1/720/ib_installers/ModelSimSetup-20.1.1.720-linux.run
RUN chmod a+x ModelSimSetup-20.1.1.720-linux.run
RUN ./ModelSimSetup-20.1.1.720-linux.run --mode unattended --installdir /tools --accept_eula 1
# Make it available through the  users  group. Troubleshoot here: https://askubuntu.com/questions/455000/group-permissions-allow-but-still-get-permission-denied
RUN chgrp -R users /tools/modelsim_ase

# Switch to  user  for Python stuff
USER user
WORKDIR /home/user

# Python and COCOTB
RUN curl https://pyenv.run | bash
COPY pyenv.sourceme /home/user
RUN source pyenv.sourceme && pyenv update && pyenv install 3.6 && pyenv global 3.6
RUN source pyenv.sourceme && pip install --upgrade pip && pip install cocotb && pip install cocotb-bus && pip install pytest && pip install fxpmath

# Env
RUN cat pyenv.sourceme >> /home/user/.bashrc && rm -f pyenv.sourceme
RUN echo "export PATH=\"\${PATH}:/tools/modelsim_ase/bin\"" >> /home/user/.bashrc

ENTRYPOINT ["/bin/bash"]
