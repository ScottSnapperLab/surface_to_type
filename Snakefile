"""Snakemake file."""
import logging
log = logging.getLogger(__name__)

from pprint import pprint

import os
import inspect

from pathlib import Path

import ruamel.yaml as yaml

import pandas as pd
import numpy as np

from matplotlib import pyplot as plt
import seaborn as sns
sns.set_style("whitegrid")

import munch


from surface_to_type.rules import pathify_by_key_ends, SnakeRule, SnakeRun, recode_graph


# Metadata
__author__ = "Gus Dunn"
__email__ = "w.gus.dunn@gmail.com"


#### COMMON RUN STUFF ####
ORIGINAL_CONFIG_AS_STRING = yaml.dump(config, default_flow_style=False)
config = pathify_by_key_ends(config)
config = munch.munchify(config)

RUN = SnakeRun(cfg=config)

PRE = []
ALL = []

# add specific useful stuff to RUN
# RUN.globals.var_name = useful stuff



############ BEGIN PIPELINE RULES ############
# # ------------------------- #
# #### SAVE_RUN_CONFIG ####
# SAVE_RUN_CONFIG = SnakeRule(run=RUN, name="SAVE_RUN_CONFIG")
# SAVE_RUN_CONFIG.o.file = RUN.out_dir / "{NAME}.yaml".format(NAME=RUN.name)
#
#
#
# rule save_run_config:
#     # input:
#     output:
#         file=str(SAVE_RUN_CONFIG.o.file)
#
#     run:
#         with open(output.file, 'w') as cnf_out:
#             cnf_out.write(ORIGINAL_CONFIG_AS_STRING)
#
# PRE.append(rules.save_run_config.output)
# ALL.append(rules.save_run_config.output)



# ------------------------- #
#### EXAMPLE_RULE_FILTER_SUBJECTS_VCFS ####
EXAMPLE_RULE_FILTER_SUBJECTS_VCFS = SnakeRule(run=RUN, name="EXAMPLE_RULE_FILTER_SUBJECTS_VCFS")

# input
EXAMPLE_RULE_FILTER_SUBJECTS_VCFS.i.subjects_vcf = str(EXAMPLE_RULE_FILTER_SUBJECTS_VCFS.IN.VCF_DIR / "{vcf}.vcf.gz"),
EXAMPLE_RULE_FILTER_SUBJECTS_VCFS.i.filtered_gtf = FILTER_GTF.o.filtered_gtf

# output
EXAMPLE_RULE_FILTER_SUBJECTS_VCFS.o.subjects_filtered_vcf = str(EXAMPLE_RULE_FILTER_SUBJECTS_VCFS.out_dir / "{vcf}.filtered.vcf")

EXAMPLE_RULE_FILTER_SUBJECTS_VCFS.o.subjects_filtered_vcf_expd = expand(EXAMPLE_RULE_FILTER_SUBJECTS_VCFS.o.subjects_filtered_vcf,
                                                                        vcf=RUN.globals.input_vcfs)


# ---
rule EXAMPLE_RULE_FILTER_SUBJECTS_VCFS:
    log:
        path=str(EXAMPLE_RULE_FILTER_SUBJECTS_VCFS.log)

    input:
        subjects_vcf=EXAMPLE_RULE_FILTER_SUBJECTS_VCFS.i.subjects_vcf,
        filtered_gtf=EXAMPLE_RULE_FILTER_SUBJECTS_VCFS.i.filtered_gtf,

    output:
        subjects_filtered_vcf=EXAMPLE_RULE_FILTER_SUBJECTS_VCFS.o.subjects_filtered_vcf,

    run:
        shell("vt view -H {input.subjects_vcf} > {output.subjects_filtered_vcf} 2> {log.path}")
        
        shell("bedtools intersect -u -a {input.subjects_vcf} -b {input.filtered_gtf} >> "
              " {output.subjects_filtered_vcf} 2>> {log.path}")

ALL.append(EXAMPLE_RULE_FILTER_SUBJECTS_VCFS.o.subjects_filtered_vcf_expd)


# ------------------------- #


#### ALL ####
# ---
rule all:
    input: ALL

#### PRE ####
# ---
rule pre:
    input: PRE


# ------------------------- #
#### DRAW_RULE_GRAPH ####
DRAW_RULE_GRAPH = SnakeRule(run=RUN, name="DRAW_RULE_GRAPH")

# params
DRAW_RULE_GRAPH.p.pretty_names = RUN.pretty_names
# DRAW_RULE_GRAPH.p.use_pretty_names = config.COMMON.DRAW_PRETTY_NAMES

# input

# output
DRAW_RULE_GRAPH.o.rule_graph_dot = str(DRAW_RULE_GRAPH.out_dir / "rule_graph.dot")
DRAW_RULE_GRAPH.o.recoded_rule_graph_dot = str(DRAW_RULE_GRAPH.out_dir / "recoded_rule_graph.dot")
DRAW_RULE_GRAPH.o.recoded_rule_graph_svg = str(DRAW_RULE_GRAPH.out_dir / "recoded_rule_graph.svg")

# ---
rule draw_rule_graph:
    log:
        path=str(DRAW_RULE_GRAPH.log)

    params:
        pretty_names=DRAW_RULE_GRAPH.p.pretty_names,
        # use_pretty_names=DRAW_RULE_GRAPH.p.use_pretty_names,

    input:
        Snakefile=str(RUN.snakefile.absolute()),
        config=str(SAVED_CONFIG),

    output:
        rule_graph_dot=DRAW_RULE_GRAPH.o.rule_graph_dot,
        recoded_rule_graph_dot=DRAW_RULE_GRAPH.o.recoded_rule_graph_dot,
        recoded_rule_graph_svg=DRAW_RULE_GRAPH.o.recoded_rule_graph_svg,

    run:
        rule_name = config.COMMON.DRAW_RULE
        shell("snakemake -p -s {input.Snakefile}  --configfile {input.config} "+rule_name+" --rulegraph > {output.rule_graph_dot}")

        recode_graph(dot=output.rule_graph_dot,
                         new_dot=output.recoded_rule_graph_dot,
                         pretty_names=RUN.pretty_names,
                         rules_to_drop=['save_run_config',rule_name],
                         color="#50D0FF",
                         use_pretty_names=False)

        shell("dot -Tsvg {output.recoded_rule_graph_dot} -o {output.recoded_rule_graph_svg} -v ; echo ''")


# ------------------------- #
#### DRAW_DAG_GRAPH ####
DRAW_DAG_GRAPH = SnakeRule(run=RUN, name="DRAW_DAG_GRAPH")

# params
DRAW_DAG_GRAPH.p.pretty_names = RUN.pretty_names
DRAW_DAG_GRAPH.p.use_pretty_names = config.COMMON.DRAW_PRETTY_NAMES

# input

# output
DRAW_DAG_GRAPH.o.dag_graph_dot = str(DRAW_DAG_GRAPH.out_dir / "dag_graph.dot")
DRAW_DAG_GRAPH.o.recoded_dag_graph_dot = str(DRAW_DAG_GRAPH.out_dir / "recoded_dag_graph.dot")
DRAW_DAG_GRAPH.o.recoded_dag_graph_svg = str(DRAW_DAG_GRAPH.out_dir / "recoded_dag_graph.svg")

# ---
rule draw_dag_graph:
    log:
        path=str(DRAW_DAG_GRAPH.log)

    params:
        pretty_names=DRAW_DAG_GRAPH.p.pretty_names,
        use_pretty_names=DRAW_DAG_GRAPH.p.use_pretty_names,

    input:
        Snakefile=str(RUN.snakefile.absolute()),
        config=str(SAVED_CONFIG),

    output:
        dag_graph_dot=DRAW_DAG_GRAPH.o.dag_graph_dot,
        recoded_dag_graph_dot=DRAW_DAG_GRAPH.o.recoded_dag_graph_dot,
        recoded_dag_graph_svg=DRAW_DAG_GRAPH.o.recoded_dag_graph_svg,

    run:
        rule_name = config.COMMON.DRAW_RULE
        shell("snakemake -p -s {input.Snakefile}  --configfile {input.config} "+rule_name+" --dag > {output.dag_graph_dot}")

        recode_graph(dot=output.dag_graph_dot,
                         new_dot=output.recoded_dag_graph_dot,
                         pretty_names=RUN.pretty_names,
                         rules_to_drop=['save_run_config',rule_name],
                         color="#50D0FF",
                         use_pretty_names=False)

        shell("dot -Tsvg {output.recoded_dag_graph_dot} -o {output.recoded_dag_graph_svg} -v ; echo ''")
