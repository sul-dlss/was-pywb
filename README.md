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

and then running the tests in the pywb container:

    docker compose exec pywb bundle exec rake

You can run the tests locally with `bundle exec rake` if you want, but you will need to have a working Python environment and pywb installed for them to pass.

[pywb]: https://pywb.readthedocs.io/
[nginx]: https://nginx.org/

## Deploy

The was-pywb application is deployable via Capistrano like our other team projects, even though the app itself requires Python to run.

It is also deployable via the sdr-deploy application for mass-deploys (e.g., for weekly dependency updates).

**NOTE**: Every time was-pywb is deployed, `pip3 install -r requirements.txt` is run which---given none of the app's dependencies have been pinned to particular versions---should always result in running the app on the latest matrix of dependencies that work together. Thus, no weekly update PRs (via JenkinsCI) are needed for was-pywb.
