# was-pywb

This repository contains a Docker configuration for a SUL [pywb] instance for use in development. It uses [nginx] as a reverse proxy in front of pywb, which is configured to use [OutbackCDX] for indexing.  It uses the default configuration of the stage and prod instances.

## Develop

Start the services:

```bash
$ docker compose up --build --detach
```

Copy a test WARC file into the container, where pywb is configured to look:

```
$ docker compose cp test-data/apod.warc.gz pywb:web-archiving-stacks/data/collections/apod.warc.gz
```

3. Index the data so that pywb can find things:

```
$ docker compose run --rm pywb cdxj-indexer /web-archiving-stacks/data/collections/apod.warc.gz --post --sort --output /web-archiving-stacks/data/indexes/index.cdxj
```

4. View a page:

Open http://localhost:8080/ in your browser and select the `was` collection and lookup this URL:

   https://apod.nasa.gov

[pywb]: https://pywb.readthedocs.io/
[nginx]: https://nginx.org/
