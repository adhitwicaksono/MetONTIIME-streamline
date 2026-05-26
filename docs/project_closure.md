# Project Closure Note: MetONTIIME-streamline

## Status

MetONTIIME-streamline is now considered an archived exploratory fork.

This repository was created to examine whether the original MetONTIIME pipeline could be streamlined into a simpler, more user-friendly workflow for Oxford Nanopore Technologies (ONT) metabarcoding data and QIIME2-compatible downstream analysis.

## What we learned

The original MetONTIIME workflow is scientifically useful. It provides a pipeline concept for processing ONT metabarcoding reads into QIIME2-related outputs using filtering, dereplication, clustering, taxonomy assignment, visualization, and diversity analysis.

However, during inspection and testing, several major usability issues became clear:

- the workflow depends on Nextflow and Docker by default
- the Docker image can be large and difficult to manage on storage-limited systems
- the configuration file mixes user parameters, biological thresholds, pipeline switches, and container/executor settings
- input modes are hidden behind the `concatenateFastq` flag
- database preparation is not sufficiently beginner-friendly
- several workflow steps rely on side-effect-heavy output directories rather than explicit Nextflow channels
- newer Nextflow versions required syntax compatibility fixes
- WSL/Docker storage behavior can become a major barrier for users working on ordinary laptops

These issues do not invalidate the biological goal. Instead, they show that a different architecture is needed.

## Why development is stopping here

The aim of this fork was not to create a heavy production pipeline. The aim was to make ONT metabarcoding analysis feel closer to a normal QIIME2 workflow.

After testing, it became clear that making the existing Nextflow/Docker workflow user-friendly would require substantial restructuring.

Rather than continuing to patch the inherited architecture, we decided to start a new independent project with a clearer design.

## Successor project

The successor project is:

**NanoBridge-QIIME2**

Short name:

**nbQIIME2**

Planned purpose:

> A lightweight bridge from Oxford Nanopore amplicon/metabarcoding FASTQ reads to QIIME2-compatible microbiome outputs.

NanoBridge-QIIME2 will be designed as a local QIIME2-native helper first, with Docker/Nextflow treated as optional rather than mandatory.

## Relationship to MetONTIIME

MetONTIIME remains an important inspiration and reference point.

MetONTIIME-streamline should be understood as:

- a usability audit
- a documentation improvement attempt
- a practical exploration of ONT-to-QIIME2 workflow needs
- a bridge toward the design of NanoBridge-QIIME2

This repository is not intended to replace the original MetONTIIME project.

## Preserved materials

This repository preserves:

- rewritten README documentation
- input mode documentation
- configuration guide
- database preparation guide
- Zymo demo structure
- audit notes on the original Nextflow workflow
- notes on workflow pain points and future design directions

## Final conclusion

MetONTIIME-streamline showed that the scientific need is real:

> ONT metabarcoding users need an easier path into the QIIME2 ecosystem.

But the solution should be lighter, more transparent, and less dependent on container-heavy workflow machinery.

The next step is NanoBridge-QIIME2.
