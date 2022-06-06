# was-pywb

This repository contains configuration and utilities for the (soon to be released) [pywb] service running at swap.stanford.edu.
A Docker configuration is included for development, which uses [nginx] as a reverse proxy in front of pywb.

## Develop

When developing you can start the services, which will add some WARC and CDXJ data from `test-data` to the container:

```bash
$ docker compose up --build --detach
```

Then you should be able to open http://localhost:8080/ in your browser and select the `was` collection and lookup this URL:

   https://apod.nasa.gov

If you would like to test other WARC data you can copy it into pywb container:

```
$ docker compose cp test-data/data.warc.gz pywb:web-archiving-stacks/data/collections/data.warc.gz
```

Then you will need to update the index by running `cdx-indexer`:

```
$ docker compose exec pywb cdxj-indexer /web-archiving-stacks/data/collections/ --output /web-archiving-stacks/data/indexes/index.cdxj --sort --post-append
```

## Test

You can run the unit tests by starting the docker containers:

    docker compose up --detach

and then running the tests:

    bundle exec rake

[pywb]: https://pywb.readthedocs.io/
[nginx]: https://nginx.org/
