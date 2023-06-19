FROM python:3.8
RUN apt update

# install python
RUN apt install -y ruby-full

# create the directory where WARC data and CDX indexes live
RUN mkdir -p /web-archiving-stacks/data/collections/
RUN mkdir -p /web-archiving-stacks/data/indexes/cdxj

# add some WARC and CDXJ data for testing
ADD ./test-data/apod.warc.gz /web-archiving-stacks/data/collections/apod.warc.gz
ADD ./test-data/apod.cdxj /web-archiving-stacks/data/indexes/cdxj/apod.cdxj
ADD ./test-data/stanford.warc.gz /web-archiving-stacks/data/collections/stanford.warc.gz
ADD ./test-data/stanford.cdxj /web-archiving-stacks/data/indexes/cdxj/stanford.cdxj

# add the ALCJ file for testing
ADD ./test-data/access.aclj /web-archiving-stacks/data/access.aclj

# add our code
WORKDIR /home/was/swap/current/
ADD . /home/was/swap/current

# Ruby dependencies for testing and indexing
RUN gem install bundler
RUN bundle config git.allow_insecure true
RUN bundle install

# Python dependencies for pywb
WORKDIR /home/was/swap/current/pywb
RUN pip3 install poetry
RUN poetry install

# run!
CMD ["poetry", "run", "uwsgi", "uwsgi.ini"]
