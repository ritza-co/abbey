FROM alpine:3.18.4

WORKDIR /workspace

RUN apk add --no-cache curl && \
    # gnupg software-properties-common sudo && \      # python3 py3-pip && \
    # install aws
    # pip3 install --no-cache-dir awscli && \
    # aws --version
    # install terraform
    curl -o terra.zip https://releases.hashicorp.com/terraform/1.6.3/terraform_1.6.3_linux_amd64.zip && \
    unzip terra.zip -d /usr/bin && \
    rm terra.zip && \
    terraform version