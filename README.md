# MetONTIIME-streamline

> [!NOTE]
> **Project status: archived exploratory fork**
>
> MetONTIIME-streamline began as an attempt to make the original MetONTIIME workflow easier to use for Oxford Nanopore metabarcoding data and QIIME2-compatible downstream analysis.
>
> During testing, we found that the original Nextflow/Docker-centered architecture is scientifically useful but too heavy for the lightweight, beginner-friendly workflow we want to build.
>
> This repository is therefore preserved as an exploratory fork, documentation archive, and audit record.
>
> Active development is moving toward a new independent project:
>
> **NanoBridge-QIIME2 (nbQIIME2)** — a lightweight local command-line helper for converting Oxford Nanopore amplicon/metabarcoding FASTQ data into QIIME2-compatible outputs without requiring Docker or Nextflow by default.

**MetONTIIME-streamline** is a user-friendly fork of **MetONTIIME**, designed to make Oxford Nanopore Technologies (ONT) metabarcoding analysis easier to run, inspect, and connect with the QIIME2 ecosystem.

The goal of this fork is simple:

> Take ONT metabarcoding FASTQ files and produce QIIME2-compatible outputs with fewer fragile manual steps.

MetONTIIME-streamline does **not** aim to replace QIIME2.  
Instead, it acts as a bridge between ONT long-read metabarcoding data and downstream QIIME2-style microbiome analysis.

---

## Why this fork exists

The original MetONTIIME pipeline is scientifically useful, but running it can be tedious for new users because it depends heavily on manual configuration through `metontiime2.conf`.

This fork aims to improve:

- clearer input/output structure
- simpler command-line usage
- better documentation
- easier benchmarking
- safer parameter handling
- QIIME2 downstream compatibility
- reproducible reporting for ONT metabarcoding projects

The long-term target is to make ONT metabarcoding analysis feel closer to a normal QIIME2 workflow, while still respecting the specific challenges of ONT reads.

---

## Relationship to the original MetONTIIME

This repository is a fork of:

```text
https://github.com/MaestSi/MetONTIIME
```

The original MetONTIIME is a Nextflow-based metabarcoding pipeline for ONT data using the QIIME2 framework.

MetONTIIME-streamline currently preserves the original pipeline structure, but will gradually add:

- clearer documentation
- streamlined configuration templates
- input validation
- simplified wrapper commands
- benchmark examples
- improved reporting
- downstream QIIME2 compatibility notes

Please cite the original MetONTIIME work when using this pipeline.

---

## What this pipeline is for

MetONTIIME-streamline is intended for ONT metabarcoding datasets such as:

- full-length 16S rRNA amplicons
- 18S rRNA amplicons
- ITS amplicons
- other marker-gene metabarcoding datasets, depending on the reference database used

Typical use cases include:

- environmental microbiome profiling
- microbial community analysis
- biodiversity screening
- teaching ONT metabarcoding workflows
- preparing QIIME2-compatible outputs from ONT data

---

## What this pipeline is not

MetONTIIME-streamline is not:

- a replacement for QIIME2
- a replacement for EPI2ME
- a shotgun metagenomics pipeline
- a de novo genome assembly workflow
- a universal taxonomic classifier
- a magic correction tool for poor-quality ONT reads

ONT metabarcoding data can be noisy. Good results still depend on:

- good sequencing quality
- appropriate marker design
- correct barcode/demultiplexing strategy
- suitable length and quality filtering
- suitable reference database
- careful biological interpretation

---

## Current status

This repository is currently in an early streamlining stage.

At the moment, the pipeline still follows the original MetONTIIME/Nextflow structure.

Planned improvements include:

```text
Phase 1 — Documentation cleanup
Phase 2 — Input/output structure clarification
Phase 3 — Example configuration templates
Phase 4 — Validation helper scripts
Phase 5 — Simple command-line wrapper
Phase 6 — Benchmarking with real ONT metabarcoding data
Phase 7 — QIIME2 downstream compatibility guide
```

---

## Requirements

The original MetONTIIME pipeline requires:

- Nextflow
- Docker or Singularity/Apptainer
- QIIME2-compatible reference database files
- demultiplexed or barcode-separated ONT FASTQ files

Recommended:

- Linux or WSL2
- Conda/Mamba
- Docker
- sufficient storage for intermediate files
- basic familiarity with command-line workflows

---

## Installation

Clone this fork:

```bash
git clone https://github.com/adhitwicaksono/MetONTIIME-streamline.git
cd MetONTIIME-streamline
chmod 755 *
```

Check Nextflow:

```bash
nextflow -version
```

Check Docker:

```bash
docker --version
```

---

## Recommended project structure

For a clean analysis, organize your files like this:

```text
project_name/
├── raw_fastq/
│   ├── sample01.fastq.gz
│   ├── sample02.fastq.gz
│   └── sample03.fastq.gz
│
├── metadata/
│   └── sample-metadata.tsv
│
├── database/
│   ├── db-sequences.fasta
│   ├── db-taxonomy.tsv
│   ├── db-sequences.qza
│   └── db-taxonomy.qza
│
├── configs/
│   └── metontiime2.local.conf
│
└── results/
```

For now, raw FASTQ data should generally **not** be committed to GitHub unless the dataset is public and properly cleared for release.

---

## Input files

### 1. FASTQ files

Input FASTQ files should be either:

```text
.fastq
.fastq.gz
```

Recommended naming:

```text
sample01.fastq.gz
sample02.fastq.gz
sample03.fastq.gz
```

Avoid spaces in file names.

Good:

```text
pulau_lombok_sample01.fastq.gz
```

Avoid:

```text
Pulau Lombok Sample 01 final fixed.fastq.gz
```

---

### 2. Sample metadata file

The sample metadata file should be a tab-separated file:

```text
sample-metadata.tsv
```

Example:

```tsv
sample-id	location	sample-type	description
sample01	Gili_Meno	lake_water	surface_water_sample_01
sample02	Gili_Meno	lake_water	surface_water_sample_02
sample03	Gili_Meno	lake_water	surface_water_sample_03
```

The `sample-id` values should match the FASTQ file names as closely as possible.

For example:

```text
sample01.fastq.gz  →  sample01
sample02.fastq.gz  →  sample02
```

---

### 3. Reference database

MetONTIIME can use marker-gene databases such as:

- SILVA for 16S/18S rRNA
- Greengenes for 16S rRNA
- UNITE for fungal ITS
- custom FASTA + taxonomy TSV databases

Typical database files:

```text
db-sequences.fasta
db-taxonomy.tsv
db-sequences.qza
db-taxonomy.qza
```

The FASTA file contains reference sequences.

The taxonomy TSV file should map sequence IDs to taxonomy strings.

Example:

```tsv
Feature ID	Taxon
seq001	Bacteria; Proteobacteria; Gammaproteobacteria; Enterobacterales
seq002	Bacteria; Firmicutes; Bacilli; Lactobacillales
```

---

## Running the original Nextflow pipeline

At the current stage, the pipeline can still be run using the original MetONTIIME-style Nextflow command:

```bash
nextflow -c metontiime2.conf run metontiime2.nf \
  --workDir="/path/to/fastq_directory" \
  --resultsDir="/path/to/results_directory" \
  -profile docker
```

For Singularity/Apptainer:

```bash
nextflow -c metontiime2.conf run metontiime2.nf \
  --workDir="/path/to/fastq_directory" \
  --resultsDir="/path/to/results_directory" \
  -profile singularity
```

---

## Important configuration parameters

The original pipeline uses `metontiime2.conf` to set many parameters.

Important parameters include:

```text
workDir
sampleMetadata
dbSequencesFasta
dbTaxonomyTsv
dbSequencesQza
dbTaxonomyQza
classifier
maxNumReads
minReadLength
maxReadLength
minQual
extraEndsTrim
clusteringIdentity
minIdentity
minQueryCoverage
taxaLevelDiversity
numReadsDiversity
resultsDir
```

For ONT full-length 16S data, parameters commonly need careful tuning.

Example starter values:

```text
minReadLength       = 1200
maxReadLength       = 1700
minQual             = 10
extraEndsTrim       = 0
clusteringIdentity  = 0.97
classifier          = "VSEARCH"
minIdentity         = 0.80
minQueryCoverage    = 0.80
```

These are not universal values. Adjust them according to the marker, primer pair, sequencing chemistry, and expected amplicon length.

---

## Planned streamlined command

The long-term goal of this fork is to support a simpler command such as:

```bash
metontiime-streamline run \
  --input raw_fastq/ \
  --metadata metadata/sample-metadata.tsv \
  --db-sequences database/db-sequences.qza \
  --db-taxonomy database/db-taxonomy.qza \
  --marker 16s-full-length \
  --profile docker \
  --out results/
```

This command is not yet fully implemented.

The first development goal is to create a wrapper that validates inputs, generates a safe configuration file, and runs the underlying Nextflow workflow.

---

## Expected outputs

A successful run should produce QIIME2-compatible files such as:

```text
results/
├── qza/
│   ├── table.qza
│   ├── rep-seqs.qza
│   └── taxonomy.qza
│
├── qzv/
│   ├── taxa-barplot.qzv
│   ├── demux-summary.qzv
│   └── diversity-visualizations.qzv
│
├── exports/
│   ├── feature-table.tsv
│   ├── taxonomy.tsv
│   ├── rep-seqs.fasta
│   └── table.biom
│
├── logs/
│   └── pipeline.log
│
└── reports/
    └── run-summary.md
```

Exact output names may differ depending on the current MetONTIIME process settings.

---

## QIIME2 downstream compatibility

The main target of MetONTIIME-streamline is to generate outputs that can be used in the QIIME2 ecosystem.

Potential downstream analyses include:

- taxonomy barplots
- alpha diversity
- beta diversity
- rarefaction analysis
- feature table export
- BIOM export
- Krona visualization
- Gneiss-style compositional analysis
- PICRUSt-style functional prediction preparation, where appropriate

Example QIIME2 visualization:

```bash
qiime tools view results/qzv/taxa-barplot.qzv
```

Or upload `.qzv` files to:

```text
https://view.qiime2.org/
```

---

## Benchmark dataset: Gili Meno lake ONT metabarcoding data

This fork will be benchmarked using an old ONT metabarcoding FASTQ dataset from Gili Meno lake, Indonesia.

The benchmark dataset will be used to test:

- input handling
- FASTQ quality filtering
- read length distribution
- taxonomic assignment
- feature table generation
- QIIME2 compatibility
- reproducibility of outputs
- usability compared with the original MetONTIIME workflow

The raw FASTQ data will not be committed to this repository unless it is cleared for public release.

Planned local benchmark structure:

```text
benchmark_data/
└── gili_meno_lake_ont/
    ├── raw_fastq/
    ├── metadata/
    ├── configs/
    ├── original_metontiime_results/
    ├── streamline_results/
    └── benchmark_notes.md
```

Planned public example structure:

```text
examples/
└── gili_meno_lake_ont/
    ├── README.md
    ├── sample-metadata-template.tsv
    ├── expected_file_structure.txt
    └── run_example.sh
```

---

## Development roadmap

### v0.1 — Documentation cleanup

- Rewrite README
- Clarify project purpose
- Correct fork installation instructions
- Add input/output explanation
- Add benchmark plan
- Preserve original MetONTIIME credit

### v0.2 — Configuration templates

- Add example configuration files
- Add full-length 16S template
- Add 18S template
- Add ITS template
- Add Docker and Singularity examples

### v0.3 — Input validation

- Validate FASTQ directory
- Validate metadata TSV
- Check sample ID consistency
- Check database file existence
- Warn about spaces in file names
- Warn about missing `.qza` files

### v0.4 — Streamlined wrapper

- Add simple CLI entry point
- Generate config file automatically
- Run Nextflow internally
- Capture logs
- Write run summary

### v0.5 — Benchmark release

- Add Gili Meno benchmark notes
- Compare original MetONTIIME vs streamlined wrapper
- Document runtime and output differences
- Add downstream QIIME2 compatibility tests

### v1.0 — Stable release

- User-facing command-line tool
- Validated example dataset
- Clear documentation
- Reproducible output report
- Citation file
- Archived release

---

## Troubleshooting

### Problem: Nextflow cannot find input FASTQ files

Check that your input directory contains `.fastq` or `.fastq.gz` files.

```bash
ls raw_fastq/
```

Avoid nested directories unless the pipeline process expects them.

---

### Problem: Docker permission error

Try:

```bash
docker run hello-world
```

If Docker fails, check whether your user has permission to run Docker.

---

### Problem: Sample metadata does not match FASTQ names

Check that sample IDs in the metadata match FASTQ file prefixes.

Example:

```text
sample01.fastq.gz
```

should correspond to:

```text
sample01
```

in the metadata file.

---

### Problem: Too few reads remain after filtering

Your filtering thresholds may be too strict.

Check:

```text
minReadLength
maxReadLength
minQual
```

For full-length 16S, reads may vary around the expected amplicon length. ONT data can also have wider length distributions than short-read data.

---

### Problem: Too many unclassified reads

Possible causes:

- wrong marker database
- wrong primer/amplicon target
- poor read quality
- overly strict identity threshold
- incomplete database
- non-target amplification
- environmental organisms poorly represented in the database

Try adjusting:

```text
minIdentity
minQueryCoverage
classifier
database choice
```

---

### Problem: QIIME2 cannot read output files

Check that the output is a valid `.qza` or `.qzv` artifact.

You can inspect artifacts using:

```bash
qiime tools peek file.qza
```

---

## Citation

If you use this fork, please cite the original MetONTIIME work and related tools.

### Original MetONTIIME manuscript

Matoute, A.; Maestri, S.; Saout, M.; Laghoe, L.; Simon, S.; Blanquart, H.; Hernandez Martinez, M.A.; Pierre Demar, M.  
**Meat-Borne-Parasite: A Nanopore-Based Meta-Barcoding Work-Flow for Parasitic Microbiodiversity Assessment in the Wild Fauna of French Guiana.**  
*Current Issues in Molecular Biology* 2024, 46, 3810–3821.  
https://doi.org/10.3390/cimb46050237

### QIIME2

Bolyen, E.; Rideout, J.R.; Dillon, M.R.; Bokulich, N.A.; Abnet, C.C.; Al-Ghalith, G.A.; Alexander, H.; Alm, E.J.; Arumugam, M.; Asnicar, F.; et al.  
**Reproducible, interactive, scalable and extensible microbiome data science using QIIME 2.**  
*Nature Biotechnology* 2019, 37, 852–857.  
https://doi.org/10.1038/s41587-019-0209-9

### Nextflow

Di Tommaso, P.; Chatzou, M.; Floden, E.W.; Barja, P.P.; Palumbo, E.; Notredame, C.  
**Nextflow enables reproducible computational workflows.**  
*Nature Biotechnology* 2017, 35, 316–319.  
https://doi.org/10.1038/nbt.3820

---

## License

This fork follows the license terms of the original MetONTIIME repository.

Please check the `LICENSE` file for details.

---

## Maintainer

MetONTIIME-streamline fork maintained by:

```text
Adhityo Wicaksono
```

This fork is developed as a practical bioinformatics usability project for ONT metabarcoding workflows, environmental microbiome analysis, and QIIME2-compatible downstream exploration.
