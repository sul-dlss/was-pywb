FROM ubuntu:20.04

# update system dependencies
RUN apt update

# install python depdendencies
RUN apt install -y python3-dev python3-pip

# create the app dir
RUN mkdir -p /home/was/current

# create the directory where WARC data and CDX indexes live
RUN mkdir -p /web-archiving-stacks/data/collections
RUN mkdir /web-archiving-stacks/data/indexes

# add our configuration files
ADD pywb /home/was/current

# install python dependencies
WORKDIR /home/was/current
RUN pip3 install -r requirements.txt

# run!
CMD ["uwsgi", "uwsgi.ini"]
