FROM webrecorder/pywb:2.6.7

WORKDIR /pywb
ADD pywb /pywb

CMD ["uwsgi", "uwsgi.ini"]
