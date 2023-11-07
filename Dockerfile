FROM alpine:3.18.4

WORKDIR /workspace

RUN apk add aws-cli terraform

# # install terraform
# RUN apk add --no-cache curl && \
#     curl -o terra.zip https://releases.hashicorp.com/terraform/1.6.3/terraform_1.6.3_linux_amd64.zip && \
#     unzip terra.zip -d /usr/bin && \
#     rm terra.zip
#     # terraform -v

# # install aws
# RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"  && \
#     unzip awscliv2.zip && \
#     /workspace/aws/install && \
#     rm awscliv2.zip
#     # aws --version


# # gnupg software-properties-common sudo && \      # python3 py3-pip && \
# # pip3 install --no-cache-dir awscli && \


