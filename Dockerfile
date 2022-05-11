FROM webrecorder/pywb:2.6.7

WORKDIR /pywb
ADD pywb /pywb

RUN mkdir -p /data/pywb/

CMD ["uwsgi", "uwsgi.ini"]
