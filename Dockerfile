FROM continuumio/anaconda3:latest

RUN cd /home && mkdir ubuntu

WORKDIR /home/ubuntu

CMD ["sleep", "infinity"]