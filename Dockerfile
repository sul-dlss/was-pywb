FROM ubuntu:20.04

RUN apt update
RUN apt install -y python3-dev python3-pip

RUN mkdir -p /home/was/current
RUN mkdir -p /web-archiving-stacks/data/

WORKDIR /home/was/current
ADD pywb /home/was/current

RUN pip3 install -r requirements.txt

CMD ["uwsgi", "uwsgi.ini"]
