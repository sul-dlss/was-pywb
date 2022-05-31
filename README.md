# was-pywb

This repository contains a Docker configuration for a SUL [pywb] instance for use in development. It uses [nginx] as a reverse proxy in front of pywb, which is configured to use [OutbackCDX] for indexing.  It uses the default configuration of the stage and prod instances.

## Develop

Start the services:

```bash
$ docker compose up -d
```

The `web-archiving-stacks` directory is meant to simulate the `/web-archiving-stacks` NFS share that is used in stage and prod environments. You can index some test content in your docker environment by:

```
$ cp test-data/apod.warc.gz web-archiving-stacks/data/collections/
```

3. Indexing it:

```
$ docker compose run --rm pywb cdxj-indexer /web-archiving-stacks/data/collections/apod.warc.gz --sort --output /web-archiving-stacks/data/indexes/index.cdxj --dir-root /web-archiving-stacks/data/collections
```

[pywb]: https://pywb.readthedocs.io/
[nginx]: https://nginx.org/
