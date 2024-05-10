FROM alpine:latest

# Packages
RUN apk update
RUN apk add --no-cache vim git texlive-full openssh
RUN rm -rf /var/cache/apk/*

# User
RUN adduser -g user user -D
RUN echo "user:user" | chpasswd

# Tail stuff
USER user
WORKDIR /home/user
