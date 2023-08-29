[![CircleCI](https://circleci.com/gh/sul-dlss/was-pywb.svg?style=svg)](https://circleci.com/gh/sul-dlss/was-pywb)

# was-pywb

This repository contains configuration and utilities for the [pywb] service running at swap.stanford.edu. A Docker configuration is included for development purposes. If you'd like to participate in discussion about the service please join the *#web-archiving* Slack channel, and subscribe to the 
[sul-was-support](https://mailman.stanford.edu/mailman/listinfo/sul-was-support) discussion list.

## Develop

When developing you can start the services, which will add some WARC and CDXJ data from `test-data` to the container:

```bash
$ docker compose up --build --detach
```

Then you should be able to open http://localhost:8080/ in your browser and select the `was` collection and lookup one of the following URLs:

   - https://apod.nasa.gov
   - https://stanford.edu

If you would like to test other WARC data you can copy it into pywb container:

```
$ docker compose cp test-data/apod.warc.gz pywb:web-archiving-stacks/data/collections/apod.warc.gz
$ docker compose cp test-data/stanford.warc.gz pywb:web-archiving-stacks/data/collections/stanford.warc.gz
```

Note: Wildcard copies are not currently supported by docker, so the above command needs to be executed for each individual file (i.e. `apod.warc.gz`) that you would like to include for development/testing.

Then you will need to update the index by running `cdxj-indexer` (using the Poetry Python environment):

```
$ docker compose exec pywb poetry run cdxj-indexer /web-archiving-stacks/data/collections/ --output /web-archiving-stacks/data/indexes/cdxj/index.cdxj --sort --post-append
```

### Generating WARC data

Consider the [--warc-file option of wget](https://wiki.archiveteam.org/index.php/Wget_with_WARC_output) or [ArchiveWeb.page](https://ArchiveWeb.page) (a Chrome extension) for creating local test WARC data. This can sometimes be helpful when trying to determine why certain sites are not replaying correctly.

## Debugging

Sometimes you may be trying to determine why a given web page that was archived isn't playing back correctly. This could be the case where a particular URL isn't found at all, or (more commonly) when a given page doesn't completely display (missing images, or other content). Since there are many reasons why this can happen there is a separate [Debugging](https://github.com/sul-dlss/was-pywb/wiki/Debugging) for working with these issues.

## Test

You can run the unit tests by starting the docker containers:

    docker compose up --detach

and then running the tests in the pywb container:

    docker compose exec pywb bundle exec rake

You can run the tests locally with `bundle exec rake` if you want, but you will need to have a working Python environment and pywb installed for them to pass.

[pywb]: https://pywb.readthedocs.io/

## Deploy

The was-pywb application is deployable via Capistrano like our other team projects, even though the app itself requires Python to run.

It is also deployable via the sdr-deploy application for mass-deploys (e.g., for weekly dependency updates).

## Performance Benchmarking

The `bin/benchmark` script provides a means of establishing performance metrics against was-pywb.

There are several options available when running benchmarks:
```
❯ bin/benchmark -h
Usage: benchmark [options]
    -f, --file PATH                  The input file of URLs to use for benchmarking.
    -i, --index                      Visit the search results index for the given URLs.
    -n, --num INT                    The number of times to visit the root path.
    -p, --processes INT              The number of prcessses to run in parallel.
    -r, --root-only                  Only test the was-pywb homepage
    -h, --help
```

For example, to use 100 processes to visit the 1000 websites in `urls.txt`, execute:
```
bin/benchmark -f spec/fixtures/urls.txt -p 100
```

This will produce output like:
```
❯ bin/benchmark -f spec/fixtures/urls.txt -p 100
1000 urls/100 processes on WAS-PyWB |Time: 00:00:47 | ==================================================== | Time: 00:00:47
WAS-PyWB Complete.
Total data requested: 77590863
        Average page size: 77513
        Max page size: 14513632
        Min page size: 0
Total request time: 992.623845
        Actual request time: 9.92623845
        Max request time: 44.713049
        Min request time: 0.139367
        Avg request time: 0.9916322127872127
```

Similarly, a benchmark to visit the homepage 1000 times across 100 processes can be very useful when run concurrently with the
above benchmark in order to determine the effect of various loads.
```
bin/benchmark -r -p 100 -n 1000
```

And benchmarking the search results index pages for each given URL as well:
```
bin/benchmark -f spec/fixtures/urls.txt -p 100 -i
```

## Reset Process (For QA/Stage)

### Steps

1. Clear collections: `rm -rf /web-archiving-stacks/data/collections/*`
2. Clear indexes: `rm -rf /web-archiving-stacks/data/indexes/*`
3. After `was-registrar-app` has been reset:
    i. Run the `web_archive_accessioning_spec` (`bundle exec rspec spec/features/web_archiving_accessioning_spec.rb`) integration test and verify that a `One-time WARC` is created.
    ii. Verify that `https://library.stanford.edu/sites/all/themes/sulair2016/logo.svg` is indexed: https://swap-stage.stanford.edu/was/*/https://library.stanford.edu/sites/all/themes/sulair2016/logo.svg