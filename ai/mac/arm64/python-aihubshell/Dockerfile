# 24.08.04 기준 24.04
FROM ubuntu:latest

RUN \
  apt-get update -y && \
  apt-get install -y python3

RUN apt-get install -y curl

WORKDIR /home/ubuntu
# AIHUB 계정
ENV AIHUB_ID=
# AIHUB 비밀번호
ENV AIHUB_PW=

RUN curl -o "aihubshell" https://api.aihub.or.kr/api/aihubshell.do

RUN chmod +x aihubshell && cp aihubshell /usr/bin

CMD ["sleep", "infinity"]