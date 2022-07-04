FROM centos:centos7

RUN yum update -y

RUN yum install -y python3

RUN python3 -m pip install --upgrade pip awscli

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
