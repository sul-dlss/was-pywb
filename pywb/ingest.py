#!/usr/bin/env python3

"""
ingest is a command line utility that looks for WARC files filed by collection in the 
/pywb/ingest/incoming directory. If it finds a WARC file it will move it into
a pywb collection, generate a CDXJ index, and send it to OutbackCDX.

You will want to run it in the pywb container.
"""

import logging
import requests

from pathlib import Path
from logging.handlers import RotatingFileHandler
from pywb.indexer.cdxindexer import write_cdx_index

OUTBACK_CDX = 'http://outbackcdx:8080'
BASE_DIR = Path('/pywb/')
INCOMING_DIR = BASE_DIR / 'incoming'
COLLECTIONS_DIR = BASE_DIR / 'collections' 


def main():
    logger.info('started')
    for collection in INCOMING_DIR.iterdir():
        if collection.is_dir():
            for file in collection.iterdir():
                if file.name.endswith('.warc.gz'):
                    process(collection, file)
    logger.info('stopping')


def process(collection, incoming_warc):
    logger.info('processing %s in collection %s', incoming_warc, collection)
    collection_dir = COLLECTIONS_DIR / collection.name

    warc_path = collection_dir / "archive" / incoming_warc.name
    if warc_path.is_file():
        logger.error('warc file %s already exists', warc_path)
        return None
    logger.info('moving %s to %s', incoming_warc, warc_path)
    incoming_warc.rename(warc_path)

    cdx_path = collection_dir / "indexes" / warc_path.name.replace('.warc.gz', '.cdxj')
    logger.info('generating cdx %s', cdx_path)
    write_cdx_index(
        cdx_path.open('wb'),
        warc_path.open('rb'),
        warc_path.name,
        cdxj=True
    )

    outback(cdx_path, collection)

    logger.info('finished processing %s', warc_path)


def outback(cdx_path, collection):
    with cdx_path.open('r') as fh:
        url = f"{OUTBACK_CDX}/{collection.name}"
        logger.info('starting to post %s to OutbackCDX %s', cdx_path, url)
        resp = requests.post(url, data=fh)
        logger.info('finished post %s to OutbackCDX %s [status=%s]', cdx_path, url, resp.status_code)


def get_logger():
    handler = RotatingFileHandler(
        maxBytes=1024 * 1024,
        backupCount=5,
        filename=(BASE_DIR / 'ingest.log'),
    )

    formatter = logging.Formatter('%(asctime)s %(levelname)s %(message)s')

    handler.setFormatter(formatter)

    logger = logging.getLogger('ingest')
    logger.setLevel(logging.INFO)
    logger.addHandler(handler)

    return logger


logger = get_logger()
if __name__ == "__main__":
    main()
