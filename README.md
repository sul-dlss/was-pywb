# was-pywb

This repository contains an experimental Docker configuration for SUL's [pywb] instance. It uses [nginx] as a reverse proxy in front of pywb, which is configured to use [OutbackCDX] for indexing. 

## Develop

Start the services:

```bash
$ docker compose up -d
```

Copy some test WARC data into the `incoming/public` directory:

```
$ cp test-data/apod.warc.gz pywb/incoming/public/apod.warc.gz
```

Ingest the WARC data:

```
$ docker compose exec pywb ./ingest.py
```

which will:

1. move the WARC data to `pywb/collections/public/archive/apod.warc.gz`
2. generate a CDXJ index for it at `pywb/collections/public/index/apod.cdxj`
3. POST the CDXJ index to OutbackCDX

You should now be able to open this in your browser:

[http://localhost:8080/public/20220510010324/https://apod.nasa.gov/](http://localhost:8080/public/20220510010324/https://apod.nasa.gov/)

[pywb]: https://pywb.readthedocs.io/
[OutbackCDX]: https://github.com/nla/outbackcdx
[nginx]: https://nginx.org/
