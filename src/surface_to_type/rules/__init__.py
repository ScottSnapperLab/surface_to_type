#!/usr/bin/env python
"""Provide code supporting the running and automating of Snakemake rules."""

# Imports
from pathlib import Path
import inspect

import textwrap
from collections import OrderedDict

import munch

# Metadata
__author__ = "Gus Dunn"
__email__ = "w.gus.dunn@gmail.com"


__all__ = ["pathify_by_key_ends","SnakeRun","SnakeRule", "recode_graph"]


def pathify_by_key_ends(dictionary):
    """Return a dict that has had all values with keys marked as '*_PATH' or '*_DIR' converted to Path() instances."""
    for key, value in dictionary.items():
        if isinstance(value, dict):
            pathify_by_key_ends(value)
        elif key.endswith("_PATH") or key.endswith("_DIR"):
            dictionary[key] = Path(value)

    return dictionary


class SnakeRun(object):

    """Initialize and manage information common to the whole run."""

    def __init__(self, cfg, snakefile):
        """Initialize common information for a run."""
        assert isinstance(cfg, dict)

        common = cfg["COMMON"]

        self.snakefile = snakefile
        self.globals = munch.Munch()
        self.cfg = cfg
        self.name = common["RUN_NAME"]
        self.d = common["INTERIM_DIR"]
        self.out_dir = Path("{base_dir}/{run_name}".format(base_dir=common["OUT_DIR"],
                                                           run_name=self.name
                                                           )
                            )
        self.pretty_names = {}
        self.log_dir = self.out_dir / "logs"

class SnakeRule(object):

    """Manage the initialization and deployment of rule-specific information."""

    def __init__(self, run, name, pretty_name=None):
        """Initialize logs, inputs, outputs, params, etc for a single rule."""
        assert isinstance(run, SnakeRun)

        if pretty_name is None:
            pretty_name = name

        self.run = run
        self.name = name.lower()
        self.pretty_name = pretty_name

        self.run.pretty_names[self.name] = pretty_name

        self.log_dir = run.log_dir / self.name
        self.log = self.log_dir / "{name}.log".format(name=self.name)
        self.out_dir = run.out_dir / self.name
        self.i = munch.Munch() # inputs
        self.o = munch.Munch() # outputs
        self.p = munch.Munch() # params

        self._import_config_dict()

    def _import_config_dict(self):
        """Inport configuration values set for this rule so they are directly accessable as attributes."""
        try:
            for key, val in self.run.cfg[self.name.upper()].items():
                self.__setattr__(key, val)
            self.cfg = True
        except KeyError:
            self.cfg = False



# DAG and rulegraph stuff
def digest_node_line(line):
    """Return OrderedDict of relevant line parts."""
    l = line.strip()

    d = OrderedDict()
    d["num"], fields = l.split('[')
    fields = fields.replace('rounded,dashed','rounded-dashed')
    fields = fields.rstrip('];').split(',')
    fields[-1] = fields[-1].replace('rounded-dashed','rounded,dashed')
    for f in fields:
        key, value = f.split('=')
        d[key.strip()] = value.strip().replace('"','').replace("'","")

    return d

def should_ignore_line(line, strings_to_ignore):
    """Return true if line contains a rule name in `rule_names`."""
    for string in strings_to_ignore:
        if string in line:
            return True

    return False

def recode_graph(dot, new_dot, pretty_names, rules_to_drop, color=None, use_pretty_names=True):
    """Change `dot` label info to pretty_names and alter styling."""
    if color is None:
        color = "#50D0FF"

    node_patterns_to_drop = []

    with open(dot, mode='r') as dot:
        with open(new_dot, mode='w') as new_dot:
            for line in dot:
                if '[label = "' in line:

                    # Add pretty names and single color IF pretty names are provided.
                    data = digest_node_line(line=line)
                    rule_name = data['label']

                    if use_pretty_names:
                        pretty_name = textwrap.fill(pretty_names[rule_name], width=40).replace('\n', '\\n')
                        full_name = "[{rule_name}]\\n{pretty_name}".format(rule_name=rule_name,pretty_name=pretty_name)
                        data['label'] = full_name
                        data['color'] = color
                    else:
                        pass

                    fields = ', '.join(['{k} = "{v}"'.format(k=k,v=v) for k, v in data.items()][1:])

                    if should_ignore_line(line, strings_to_ignore=rules_to_drop):
                        node_patterns_to_drop.append("\t{num} ->".format(num=data['num']))
                        node_patterns_to_drop.append("-> {num}\n".format(num=data['num']))
                        continue

                    new_line = """\t{num}[{fields}];\n""".format(num=data['num'],fields=fields)

                    new_dot.write(new_line)
                else:
                    if should_ignore_line(line, strings_to_ignore=node_patterns_to_drop):
                        continue
                    elif "fontname=sans" in line:
                        line = line.replace("fontname=sans","fontname=Cantarell")
                        line = line.replace("fontsize=10","fontsize=11")
                        new_dot.write(line)
                    else:
                        new_dot.write(line)
