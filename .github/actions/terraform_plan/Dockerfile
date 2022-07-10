FROM centos:centos7

RUN yum update -y

RUN yum install -y unzip git

RUN curl -O https://releases.hashicorp.com/terraform/0.14.11/terraform_0.14.11_linux_amd64.zip
RUN mkdir /bin/terraform
RUN unzip terraform_0.14.11_linux_amd64.zip -d /bin/terraform
ENV PATH "$PATH:/bin/terraform"

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
