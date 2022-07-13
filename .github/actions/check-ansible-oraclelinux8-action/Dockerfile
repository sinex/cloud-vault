FROM oraclelinux:8

RUN dnf update --assumeyes \
  && dnf install -y epel-release \
  && dnf install --assumeyes \
    ansible git \
  && dnf clean all \
  && ansible --version

COPY ansible-docker.sh /ansible-docker.sh
ENTRYPOINT ["/ansible-docker.sh"]
