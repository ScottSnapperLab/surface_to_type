#!/usr/bin/env python
"""Provide error classes for surface_to_type."""

# Imports
import logging
log = logging.getLogger(__name__)


# Metadata
__author__ = "Gus Dunn"
__email__ = "w.gus.dunn@gmail.com"




class SurfaceToTypeError(Exception):

    """Base error class for surface_to_type."""


class ValidationError(SurfaceToTypeError):

    """Raise when a validation/sanity check comes back with unexpected value."""
