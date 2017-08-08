#!/usr/bin/env python
"""Provide custom logging code."""

# Imports
import sys
import traceback
import logging

import textwrap
from collections import OrderedDict

from pathlib import Path
import hashlib
import gzip

import pandas as pd
import numpy as np

from munch import Munch, munchify, unmunchify
import ruamel.yaml as yaml

# Metadata
__author__ = "Gus Dunn"
__email__ = "w.gus.dunn@gmail.com"


# Functions
def setup_logging(log=None, level="INFO", path=None, stream=None):
    logging.captureWarnings(capture=True)
    
    str_to_int = {"CRITICAL": 50,
                  "ERROR": 40,
                  "WARNING": 30,
                  "INFO": 20,
                  "DEBUG": 10,
                  "NOTSET": 0,}
    
    level = str_to_int[level]
    
    if (path is None) and (stream is None):
        raise ValueError("Must provide values for at least one of [path, stream] arguments.")
        
        
    if log is None:
        log = logging.getLogger()
            
    # Set the general logging level
    log.setLevel(level)
    
    # create formatter and add it to the handlers
    formatter = logging.Formatter("[%(levelname)s][%(asctime)s][%(module)s +%(lineno)s]: %(message)s")
    
    if path is not None:
        fh = logging.FileHandler(path, mode='a')
        fh.setLevel(level)
        fh.setFormatter(formatter)
        log.addHandler(fh)
        
    if stream is not None:
        ch = logging.StreamHandler(stream)
        ch.setLevel(level)
        ch.setFormatter(formatter)
        log.addHandler(ch)
            
    return log
        
