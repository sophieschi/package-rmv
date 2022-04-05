#!/usr/bin/env python3

import logging
from json import JSONDecodeError, dump, load
from os.path import abspath, dirname, join
from sys import exit, stderr, stdout
from time import sleep

from requests import get
from requests.exceptions import RequestException

logging.basicConfig(
    format='[[%(levelname)s]] %(message)s',
    stream=stdout,
    level=logging.INFO,
)

try:
    with open('config.json', 'r') as f:
        CONFIG = load(f)
except (FileNotFoundError, JSONDecodeError):
    logging.error('Please provide a config.json file in the current working directory')
    exit(1)

STOPS = CONFIG['stop'].split(',')
KEY = CONFIG['key']
LIMIT = min(int(CONFIG.get('requests_max', 4900)), 4900)
MINUTES = CONFIG.get('request_minutes', 360) # 6 hours
OUTDIR = CONFIG.get('output_directory', abspath(dirname(__file__)))

while True:
    for stop in STOPS:
        try:
            r = get('https://www.rmv.de/hapi/departureBoard?id={stop}&duration={minutes}&format=json&accessId={key}'.format(
                stop=stop,
                minutes=MINUTES,
                key=KEY,
            ))
            r.raise_for_status()
        except RequestException as e:
            logging.exception('[{}] {}'.format(stop, repr(e)))
        else:
            logging.info('[{}] fetched successfully'.format(stop))

            with open(join(OUTDIR, '{}.json'.format(stop)), 'w') as f:
                dump(r.json(), f, indent=4)

    number_of_stops = len(STOPS)
    sleep_time = 86400 / ( LIMIT / number_of_stops)

    if sleep_time < 30:
        sleep_time = 30

    logging.info('waiting {} seconds before fetching again'.format(sleep_time))
    sleep(sleep_time)
