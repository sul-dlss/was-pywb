FROM ubuntu:20.04
RUN apt update

# install python and ruby
RUN apt install -y python3-dev python3-pip ruby ruby-dev
RUN gem install bundler

# create the directory where WARC data and CDX indexes live
RUN mkdir -p /web-archiving-stacks/data/collections/
RUN mkdir /web-archiving-stacks/data/indexes/

# add some WARC and CDXJ data for testing
ADD ./test-data/apod.warc.gz /web-archiving-stacks/data/collections/apod.warc.gz
ADD ./test-data/apod.cdxj /web-archiving-stacks/data/indexes/index.cdxj

# add our code
WORKDIR /home/was/swap/current/
ADD . /home/was/swap/current

# Ruby dependencies for testing and indexing
RUN bundle config git.allow_insecure true
RUN bundle install

# Python depdendencies for pywb
WORKDIR /home/was/swap/current/pywb
RUN pip3 install -r requirements.txt

# run!
CMD ["uwsgi", "uwsgi.ini"]
