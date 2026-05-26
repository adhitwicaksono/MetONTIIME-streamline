# Input Modes for MetONTIIME-streamline

This document explains how MetONTIIME currently expects input FASTQ files and how MetONTIIME-streamline should make those input modes clearer.

The current MetONTIIME workflow has an important hidden behavior:

```groovy
concatenateFastq = true
```

and:

```groovy
concatenateFastq = false
```

do more than simply “concatenate or not concatenate” files.

In practice, this switch controls the input structure expected by the pipeline.

---

## 1. Why input modes matter

Oxford Nanopore Technologies (ONT) metabarcoding data may arrive in different forms depending on how basecalling and demultiplexing were done.

Common cases:

```text
1. Barcode folders from ONT basecalling/demultiplexing
2. One FASTQ file per sample
3. One combined FASTQ file
4. Mixed or manually renamed FASTQ files
```

The current pipeline does not make these modes explicit enough.

MetONTIIME-streamline should make input mode selection clear, validated, and documented.

---

## 2. Current behavior in MetONTIIME

The current workflow uses:

```groovy
params.concatenateFastq
```

to decide how FASTQ input is handled.

### If `concatenateFastq = true`

The pipeline searches the input directory for folders containing the word:

```text
barcode
```

Example expected structure:

```text
raw_fastq/
├── barcode01/
│   ├── read1.fastq
│   ├── read2.fastq
│   └── read3.fastq
├── barcode02/
│   ├── read1.fastq
│   ├── read2.fastq
│   └── read3.fastq
└── barcode03/
    ├── read1.fastq
    ├── read2.fastq
    └── read3.fastq
```

The pipeline then concatenates reads inside each barcode folder and creates:

```text
results/concatenateFastq/
├── barcode01.fastq.gz
├── barcode02.fastq.gz
└── barcode03.fastq.gz
```

### If `concatenateFastq = false`

The pipeline expects existing `.fastq.gz` files directly inside the input directory.

Example expected structure:

```text
raw_fastq/
├── sample01.fastq.gz
├── sample02.fastq.gz
└── sample03.fastq.gz
```

The pipeline copies them into:

```text
results/concatenateFastq/
├── sample01.fastq.gz
├── sample02.fastq.gz
└── sample03.fastq.gz
```

---

## 3. Recommended future input mode names

Instead of using only:

```groovy
concatenateFastq = true
```

or:

```groovy
concatenateFastq = false
```

MetONTIIME-streamline should eventually expose explicit input modes:

```text
barcode_dirs
fastq_per_sample
single_fastq
```

Possible future parameter:

```groovy
inputMode = "fastq_per_sample"
```

Possible future command-line interface:

```bash
metontiime-streamline run   --input raw_fastq/   --input-mode fastq_per_sample   --metadata metadata/sample-metadata.tsv   --out results/
```

---

## 4. Mode 1 — Barcode directories

### Use this mode when

Your ONT output looks like this:

```text
raw_fastq/
├── barcode01/
├── barcode02/
├── barcode03/
└── barcode04/
```

Each barcode folder contains one or more FASTQ files.

This often happens after ONT basecalling/demultiplexing.

### Current setting

```groovy
concatenateFastq = true
```

### Recommended future setting

```groovy
inputMode = "barcode_dirs"
```

### Example structure

```text
project/
├── raw_fastq/
│   ├── barcode01/
│   │   ├── reads_0.fastq
│   │   ├── reads_1.fastq
│   │   └── reads_2.fastq
│   ├── barcode02/
│   │   ├── reads_0.fastq
│   │   └── reads_1.fastq
│   └── barcode03/
│       ├── reads_0.fastq
│       └── reads_1.fastq
│
├── metadata/
│   └── sample-metadata.tsv
│
└── results/
```

### Metadata requirement

If barcode folders are used directly as sample IDs, metadata may look like:

```tsv
sample-id	sample-name	location	sample-type
barcode01	sample01	Gili_Meno	lake_water
barcode02	sample02	Gili_Meno	lake_water
barcode03	sample03	Gili_Meno	lake_water
```

However, for human readability, it is often better to rename output FASTQ files to meaningful sample names after demultiplexing.

Example:

```text
barcode01 → gili_meno_surface_01
barcode02 → gili_meno_surface_02
barcode03 → gili_meno_sediment_01
```

---

## 5. Mode 2 — FASTQ per sample

### Use this mode when

Your input folder already contains one `.fastq.gz` file per sample:

```text
raw_fastq/
├── sample01.fastq.gz
├── sample02.fastq.gz
└── sample03.fastq.gz
```

This is the cleanest beginner-friendly input mode.

### Current setting

```groovy
concatenateFastq = false
```

### Recommended future setting

```groovy
inputMode = "fastq_per_sample"
```

### Example structure

```text
project/
├── raw_fastq/
│   ├── gili_meno_sample01.fastq.gz
│   ├── gili_meno_sample02.fastq.gz
│   └── gili_meno_sample03.fastq.gz
│
├── metadata/
│   └── sample-metadata.tsv
│
└── results/
```

### Metadata requirement

The metadata sample IDs should match the FASTQ file names without `.fastq.gz`.

Example FASTQ files:

```text
gili_meno_sample01.fastq.gz
gili_meno_sample02.fastq.gz
gili_meno_sample03.fastq.gz
```

Metadata:

```tsv
sample-id	location	sample-type	description
gili_meno_sample01	Gili_Meno	lake_water	sample_01
gili_meno_sample02	Gili_Meno	lake_water	sample_02
gili_meno_sample03	Gili_Meno	lake_water	sample_03
```

---

## 6. Mode 3 — Single FASTQ

### Use this mode when

You have only one FASTQ file:

```text
raw_fastq/
└── sample01.fastq.gz
```

This may happen with:

```text
single-sample studies
mock community demo files
subsampled test files
smoke tests
```

### Current setting

```groovy
concatenateFastq = false
```

### Recommended future setting

```groovy
inputMode = "single_fastq"
```

### Example structure

```text
examples/
└── zymo_demo/
    ├── raw_fastq/
    │   └── Zymo-GridION-EVEN-BB-SN_sup_pass_filtered_27F_1492Rw_1000_reads.fastq.gz
    ├── metadata/
    │   └── sample-metadata.tsv
    └── config/
        └── zymo_demo.example.conf
```

### Important note

For single-sample datasets, alpha diversity and taxonomic profiling can still be useful, but beta diversity comparisons are not meaningful because there is only one sample.

The current workflow checks the number of samples before running some multi-sample diversity outputs.

---

## 7. File naming rules

Good file names make QIIME2 and pipeline handling easier.

### Recommended

```text
sample01.fastq.gz
gili_meno_surface_01.fastq.gz
gili_meno_sediment_02.fastq.gz
zymo_mock_1000_reads.fastq.gz
```

### Avoid

```text
Sample 01 final.fastq.gz
Gili Meno Lake #1.fastq.gz
sample(1).fastq.gz
sample;01.fastq.gz
sample 01 fixed filtered latest.fastq.gz
```

Avoid:

```text
spaces
semicolons
parentheses
hashtags
commas
very long names
```

Use:

```text
letters
numbers
underscores
hyphens
```

---

## 8. FASTQ extension expectations

The current pipeline is most comfortable with:

```text
.fastq.gz
```

Some steps may detect `.fastq`, but the safest current input is:

```text
sample.fastq.gz
```

If you have plain `.fastq` files, compress them:

```bash
gzip sample.fastq
```

This creates:

```text
sample.fastq.gz
```

To compress many FASTQ files:

```bash
gzip *.fastq
```

---

## 9. Sample ID matching

QIIME2-style workflows are sensitive to sample IDs.

The sample ID is usually derived from the FASTQ filename.

Example:

```text
gili_meno_sample01.fastq.gz
```

becomes:

```text
gili_meno_sample01
```

Your metadata should contain:

```tsv
sample-id	location	sample-type
gili_meno_sample01	Gili_Meno	lake_water
```

If sample IDs do not match, QIIME2 metadata steps may fail.

---

## 10. How to inspect your input before running

From the project root:

```bash
find raw_fastq -maxdepth 2 -type f | head
```

Count FASTQ files:

```bash
find raw_fastq -type f | grep -E "\.fastq(\.gz)?$" | wc -l
```

Check file sizes:

```bash
ls -lh raw_fastq/
```

If using barcode folders:

```bash
find raw_fastq -maxdepth 2 -type f | grep -E "\.fastq(\.gz)?$" | head
```

---

## 11. Basic read statistics

Recommended tools:

```bash
seqkit stats raw_fastq/*.fastq.gz
```

or:

```bash
NanoPlot --fastq raw_fastq/*.fastq.gz --outdir nanoplot_qc
```

Useful things to check:

```text
number of reads
mean read length
N50 read length
minimum length
maximum length
quality distribution
per-sample imbalance
```

These statistics help determine:

```text
minReadLength
maxReadLength
minQual
maxNumReads
numReadsDiversity
```

---

## 12. Choosing input mode

Use this decision table:

| Your input looks like | Current setting | Future streamline mode |
|---|---|---|
| `barcode01/`, `barcode02/`, `barcode03/` folders | `concatenateFastq = true` | `barcode_dirs` |
| `sample01.fastq.gz`, `sample02.fastq.gz` files | `concatenateFastq = false` | `fastq_per_sample` |
| one `.fastq.gz` file only | `concatenateFastq = false` | `single_fastq` |
| mixed folders and files | reorganize first | not recommended |
| files have spaces/symbols | rename first | not recommended |

---

## 13. Recommended layout for real projects

For real analysis, use:

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
│   └── project.example.conf
│
├── qc/
│   └── nanoplot/
│
└── results/
```

For private benchmark datasets:

```text
benchmark_data/
└── gili_meno_lake_ont/
    ├── raw_fastq/
    ├── metadata/
    ├── qc/
    ├── configs/
    ├── original_metontiime_results/
    ├── streamline_results/
    └── benchmark_notes.md
```

---

## 14. Zymo demo input mode

The Zymo demo file:

```text
Zymo-GridION-EVEN-BB-SN_sup_pass_filtered_27F_1492Rw_1000_reads.fastq.gz
```

is already a FASTQ file.

Therefore, the current config should use:

```groovy
concatenateFastq = false
```

Future streamline mode:

```groovy
inputMode = "single_fastq"
```

or:

```groovy
inputMode = "fastq_per_sample"
```

because it is technically one sample-level FASTQ file.

---

## 15. Gili Meno benchmark input mode

For the Gili Meno lake ONT dataset, first determine whether the data are:

```text
barcode folders
already demultiplexed sample FASTQ files
one combined FASTQ file
```

If the files are already demultiplexed per sample:

```groovy
concatenateFastq = false
```

Future mode:

```groovy
inputMode = "fastq_per_sample"
```

If they are barcode folders:

```groovy
concatenateFastq = true
```

Future mode:

```groovy
inputMode = "barcode_dirs"
```

Before running, record:

```text
input mode
number of samples
number of FASTQ files
whether barcodes/adapters were removed
whether reads are already filtered
basecalling model
sequencing platform
marker region
primer pair
```

---

## 16. Common input mistakes

### Mistake 1: Using barcode folders with `concatenateFastq = false`

Problem:

The pipeline expects `.fastq.gz` files directly inside the input folder and may not process barcode subfolders.

Fix:

```groovy
concatenateFastq = true
```

or reorganize FASTQ files into one file per sample.

---

### Mistake 2: Using sample FASTQ files with `concatenateFastq = true`

Problem:

The pipeline searches for barcode folders and may not find the expected input.

Fix:

```groovy
concatenateFastq = false
```

---

### Mistake 3: Metadata sample IDs do not match FASTQ names

Problem:

QIIME2 metadata steps may fail.

Fix:

Rename FASTQ files or edit metadata so IDs match.

---

### Mistake 4: Files are not visible inside Docker/Singularity

Problem:

The host can see the FASTQ files, but the container cannot.

Fix:

Check container bind paths in the config.

For example, if data are under `/mnt/d`:

```groovy
containerOptions = '-v /mnt/d:/mnt/d'
```

or for Singularity:

```groovy
containerOptions = '--bind /mnt/d:/mnt/d'
```

---

### Mistake 5: Plain `.fastq` files are used when `.fastq.gz` is expected

Problem:

Some parts of the workflow may expect compressed `.fastq.gz` files.

Fix:

```bash
gzip *.fastq
```

---

## 17. Future validation checks

MetONTIIME-streamline should eventually include an input validator:

```bash
metontiime-streamline validate-input   --input raw_fastq/   --input-mode fastq_per_sample   --metadata metadata/sample-metadata.tsv
```

The validator should check:

```text
input directory exists
FASTQ files exist
FASTQ extensions are supported
barcode folders exist if barcode mode is selected
metadata file exists
metadata has sample-id column
sample IDs match FASTQ names
filenames do not contain unsafe characters
files are inside container-visible paths
```

Example output:

```text
[OK] Input directory found
[OK] 3 FASTQ files detected
[OK] Metadata file found
[OK] sample-id column detected
[OK] FASTQ names match metadata sample IDs
[WARNING] Docker bind path may not include /mnt/d/project
```

---

## 18. Summary

The current pipeline hides input behavior behind:

```groovy
concatenateFastq = true/false
```

MetONTIIME-streamline should make this explicit as:

```text
barcode_dirs
fastq_per_sample
single_fastq
```

The simplest beginner-safe recommendation is:

```text
Use one compressed FASTQ file per sample.
Avoid spaces in file names.
Make metadata sample IDs match FASTQ names.
Run a small demo before full analysis.
```
