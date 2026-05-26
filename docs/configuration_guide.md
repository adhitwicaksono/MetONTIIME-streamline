# Configuration Guide for MetONTIIME-streamline

This guide explains how to understand and edit the `metontiime2.conf` configuration file used by the current MetONTIIME workflow.

The original configuration file is powerful, but it is not beginner-friendly. It mixes together:

```text
1. input file paths
2. sample metadata paths
3. database paths
4. read filtering parameters
5. taxonomy assignment parameters
6. diversity analysis parameters
7. pipeline step switches
8. Docker/Singularity execution settings
9. per-process CPU and memory settings
```

For most users, only a small part of the config should be edited.

---

## 1. The beginner rule

If you are new to the pipeline, focus only on these sections:

```text
Input and output paths
Database files
Read filtering
Taxonomy assignment
Diversity settings
Pipeline step switches
```

Avoid changing these unless you know what you are doing:

```text
Docker profile
Singularity profile
containerOptions
executor
memory
cpus
errorStrategy
maxRetries
```

In future versions of MetONTIIME-streamline, these should be separated into beginner and advanced configuration files.

---

## 2. Minimum parameters most users must edit

The most important parameters are:

| Parameter | What it means | Beginner action |
|---|---|---|
| `workDir` | Folder containing input FASTQ files | Change to your FASTQ folder |
| `sampleMetadata` | Path to sample metadata TSV | Change to your metadata file |
| `dbSequencesFasta` | Reference database sequences in FASTA format | Change to your database FASTA |
| `dbTaxonomyTsv` | Reference taxonomy table in TSV format | Change to your database taxonomy TSV |
| `dbSequencesQza` | Name of imported QIIME2 sequence artifact | Usually leave as default |
| `dbTaxonomyQza` | Name of imported QIIME2 taxonomy artifact | Usually leave as default |
| `resultsDir` | Output folder | Change to your desired result folder |
| `classifier` | Taxonomy assignment method | Use `VSEARCH` or `BLAST` |
| `minReadLength` | Minimum read length to keep | Adjust to marker |
| `maxReadLength` | Maximum read length to keep | Adjust to marker |
| `minQual` | Minimum average read quality | Start with `10` for ONT |
| `clusteringIdentity` | De novo clustering identity | Benchmark carefully |

---

## 3. Input and output paths

### 3.1 `workDir`

Current meaning:

```groovy
workDir="/path/to/workDir"
```

Despite the name, this is not really the Nextflow work directory. In this pipeline, it means:

```text
input FASTQ directory
```

Example:

```groovy
workDir="examples/zymo_demo/raw_fastq"
```

In future MetONTIIME-streamline documentation, this should be described as:

```text
input FASTQ folder
```

or eventually renamed in wrapper logic to:

```text
--input
```

or:

```text
--fastq-dir
```

---

### 3.2 `sampleMetadata`

Current meaning:

```groovy
sampleMetadata="/path/to/sample-metadata.tsv"
```

This is the QIIME2-style metadata table.

Example:

```groovy
sampleMetadata="examples/zymo_demo/metadata/sample-metadata.tsv"
```

Minimal metadata example:

```tsv
sample-id	sample-name	sample-type	description
sample01	sample01	lake_water	Gili_Meno_lake_water_sample_01
sample02	sample02	lake_water	Gili_Meno_lake_water_sample_02
```

Important:

- `sample-id` should match FASTQ file names without `.fastq.gz`.
- Avoid spaces in sample IDs.
- Use underscores instead of spaces.

Good:

```text
gili_meno_sample01
```

Avoid:

```text
Gili Meno Sample 01
```

---

### 3.3 `resultsDir`

Current meaning:

```groovy
resultsDir="/path/to/resultsDir"
```

This is where all output folders will be created.

Example:

```groovy
resultsDir="results/zymo_demo"
```

Expected result subfolders may include:

```text
results/
├── concatenateFastq/
├── filterFastq/
├── downsampleFastq/
├── importFastq/
├── dataQC/
├── importDb/
├── derepSeq/
├── assignTaxonomy/
├── taxonomyVisualization/
├── collapseTables/
├── filterTaxa/
└── diversityAnalyses/
```

---

## 4. Database parameters

MetONTIIME needs a marker-gene database for taxonomic assignment.

The config contains four database-related parameters:

```groovy
dbSequencesFasta="/path/to/sequence.fasta"
dbTaxonomyTsv="/path/to/taxonomy.tsv"
dbSequencesQza="db_sequences.qza"
dbTaxonomyQza="db_taxonomy.qza"
```

### 4.1 `dbSequencesFasta`

Reference sequences in FASTA format.

Example:

```groovy
dbSequencesFasta="database/silva/silva-sequences.fasta"
```

### 4.2 `dbTaxonomyTsv`

Taxonomy labels for the reference sequences.

Example:

```groovy
dbTaxonomyTsv="database/silva/silva-taxonomy.tsv"
```

The IDs in the taxonomy TSV should match the IDs in the FASTA file.

Example FASTA:

```fasta
>seq001
ACGTACGTACGT
>seq002
ACGTACGTACGA
```

Example taxonomy TSV:

```tsv
seq001	Bacteria; Proteobacteria; Gammaproteobacteria
seq002	Bacteria; Firmicutes; Bacilli
```

### 4.3 `dbSequencesQza` and `dbTaxonomyQza`

These are names for the QIIME2 artifacts created after importing FASTA/TSV database files.

Example:

```groovy
dbSequencesQza="db_sequences.qza"
dbTaxonomyQza="db_taxonomy.qza"
```

If `importDb = true`, the pipeline imports:

```text
dbSequencesFasta → resultsDir/importDb/dbSequencesQza
dbTaxonomyTsv   → resultsDir/importDb/dbTaxonomyQza
```

### 4.4 Where do databases come from?

Common choices:

| Marker | Recommended database |
|---|---|
| 16S rRNA | SILVA or Greengenes2 |
| 18S rRNA | SILVA |
| ITS | UNITE |
| Custom marker | Custom FASTA + taxonomy TSV |

See:

```text
docs/database_preparation.md
```

for a more complete database guide.

---

## 5. Taxonomy assignment parameters

### 5.1 `classifier`

Current parameter:

```groovy
classifier="Vsearch"
```

Supported methods in the current workflow:

```text
VSEARCH
BLAST
```

The `.nf` script normalizes the classifier name to uppercase, so `Vsearch`, `VSEARCH`, and `vsearch` should be interpreted similarly.

Recommended beginner setting:

```groovy
classifier="VSEARCH"
```

### 5.2 `maxAccepts`

```groovy
maxAccepts=3
```

This controls how many candidate hits are considered for consensus taxonomy assignment.

Higher values may consider more possible hits but may increase ambiguity.

### 5.3 `minConsensus`

```groovy
minConsensus=0.7
```

This is the minimum fraction of assignments that must agree with the top hit for a consensus taxonomy call.

Typical range:

```text
0.5 to 1.0
```

### 5.4 `minQueryCoverage`

```groovy
minQueryCoverage=0.8
```

This is the minimum fraction of the query sequence that must align to a reference sequence.

For full-length 16S ONT data, a high value may be reasonable if reads are good and the reference database is appropriate.

### 5.5 `minIdentity`

```groovy
minIdentity=0.9
```

This is the minimum alignment identity required for a candidate taxonomic hit.

If too many reads are unclassified, possible reasons include:

```text
wrong marker database
poor read quality
too strict identity threshold
too strict query coverage threshold
environmental taxa missing from reference database
non-target amplification
```

---

## 6. Read filtering parameters

The pipeline filters reads by quality and length.

Current parameters:

```groovy
minReadLength=200
maxReadLength=5000
minQual=10
extraEndsTrim=20
```

### 6.1 `minReadLength`

Minimum read length to retain.

For full-length 16S using 27F/1492R, a reasonable starter range may be:

```groovy
minReadLength=1200
```

For ITS, this value should be adjusted because ITS length is highly variable.

### 6.2 `maxReadLength`

Maximum read length to retain.

For full-length 16S using 27F/1492R, a reasonable starter range may be:

```groovy
maxReadLength=1700
```

### 6.3 `minQual`

Minimum average PHRED score to retain a read.

Starter value:

```groovy
minQual=10
```

This may be adjusted depending on basecalling model, sequencing quality, and downstream tolerance.

### 6.4 `extraEndsTrim`

Number of bases trimmed from both ends.

Current default:

```groovy
extraEndsTrim=20
```

This may help remove primer/adaptor-edge noise, but the correct value depends on the library preparation and whether primers/adapters have already been removed.

---

## 7. Downsampling and clustering

### 7.1 `maxNumReads`

```groovy
maxNumReads=50000
```

This controls the maximum number of reads retained per sample after filtering.

If one sample has more reads than this value, random downsampling is performed.

Important current limitation:

```text
The current pipeline uses random downsampling without an explicit seed.
```

For reproducible benchmarking, MetONTIIME-streamline should add a future parameter:

```groovy
seed=42
```

and use:

```bash
seqtk sample -s ${params.seed}
```

### 7.2 `clusteringIdentity`

```groovy
clusteringIdentity=1
```

This controls de novo clustering identity in `qiime vsearch cluster-features-de-novo`.

Interpretation:

| Value | Meaning |
|---|---|
| `1.0` | Exact or near-exact clustering |
| `0.99` | Strict OTU-like clustering |
| `0.97` | Classic broader OTU-like clustering |

For ONT data, this should be benchmarked carefully.

Suggested Gili Meno benchmark comparison:

```text
clusteringIdentity = 1.00
clusteringIdentity = 0.99
clusteringIdentity = 0.97
```

---

## 8. Diversity analysis parameters

### 8.1 `taxaLevelDiversity`

```groovy
taxaLevelDiversity=6
```

This controls the taxonomic level used for non-phylogenetic diversity analyses.

Taxonomy level depends on database formatting.

A common bacterial taxonomy structure may look like:

```text
Level 1 = Kingdom / Domain
Level 2 = Phylum
Level 3 = Class
Level 4 = Order
Level 5 = Family
Level 6 = Genus
Level 7 = Species
```

But this is not always guaranteed.

### 8.2 `numReadsDiversity`

```groovy
numReadsDiversity=500
```

This is the sampling depth used for diversity analyses.

If this value is too high, samples with fewer reads may be excluded or diversity analysis may fail.

For small demo datasets, use lower values such as:

```groovy
numReadsDiversity=100
```

For real datasets, inspect feature table summaries before choosing this value.

---

## 9. Optional taxa filtering

Current parameters:

```groovy
taxaOfInterest=""
minNumReadsTaxaOfInterest=1
filterTaxa=false
```

If `filterTaxa=true`, the pipeline filters the table to retain only taxa matching `taxaOfInterest`.

Example:

```groovy
filterTaxa=true
taxaOfInterest="Proteobacteria"
minNumReadsTaxaOfInterest=10
```

Important warning:

Taxa names can contain spaces, semicolons, brackets, or other filename-unfriendly characters.

Risky example:

```groovy
taxaOfInterest="Bacteria; Proteobacteria"
```

This may create unsafe filenames.

Future MetONTIIME-streamline should sanitize taxa labels into safe filenames.

Example:

```text
raw query: Bacteria; Proteobacteria
safe slug: bacteria_proteobacteria
```

---

## 10. Pipeline step switches

The config includes switches controlling which processes run.

Current defaults:

```groovy
concatenateFastq = false
filterFastq = true
downsampleFastq = true
importFastq = true
dataQC = true
importDb = true
derepSeq = true
assignTaxonomy = true
taxonomyVisualization = true
collapseTables = true
filterTaxa = false
diversityAnalyses = true
```

### 10.1 `concatenateFastq`

This is one of the most important hidden switches.

If:

```groovy
concatenateFastq = true
```

the pipeline expects barcode folders such as:

```text
barcode01/
barcode02/
barcode03/
```

If:

```groovy
concatenateFastq = false
```

the pipeline expects existing `.fastq.gz` files in the input folder.

This should eventually become a clearer setting:

```groovy
inputMode = "barcode_dirs"
```

or:

```groovy
inputMode = "fastq_per_sample"
```

### 10.2 `filterFastq`

Runs quality and length filtering.

Usually:

```groovy
filterFastq = true
```

### 10.3 `downsampleFastq`

Runs read downsampling.

For demo datasets:

```groovy
downsampleFastq = true
```

For already-small datasets, set `maxNumReads` above the number of reads to avoid reducing data.

### 10.4 `importFastq`

Imports FASTQ files into QIIME2.

Usually:

```groovy
importFastq = true
```

### 10.5 `dataQC`

Creates QIIME2 demultiplexing/read summary visualization.

Usually:

```groovy
dataQC = true
```

### 10.6 `importDb`

Imports FASTA/TSV database files into QIIME2 artifacts.

Use:

```groovy
importDb = true
```

if you provide:

```text
dbSequencesFasta
dbTaxonomyTsv
```

If you already have QIIME2 database artifacts, database handling must be arranged carefully according to the current pipeline behavior.

### 10.7 `derepSeq`

Runs dereplication and de novo clustering.

Usually:

```groovy
derepSeq = true
```

### 10.8 `assignTaxonomy`

Assigns taxonomy using VSEARCH or BLAST.

Usually:

```groovy
assignTaxonomy = true
```

### 10.9 `taxonomyVisualization`

Creates QIIME2 taxa barplots.

Usually:

```groovy
taxonomyVisualization = true
```

### 10.10 `collapseTables`

Collapses feature tables by taxonomy level and exports tables.

Usually:

```groovy
collapseTables = true
```

### 10.11 `filterTaxa`

Optional. Use only when focusing on a specific taxon.

Default:

```groovy
filterTaxa = false
```

### 10.12 `diversityAnalyses`

Runs non-phylogenetic diversity analyses.

Usually:

```groovy
diversityAnalyses = true
```

For a single-sample dataset, some diversity analyses may be skipped or not meaningful.

---

## 11. Docker and Singularity profiles

The current config contains two main execution profiles:

```text
docker
singularity
```

Run with Docker:

```bash
nextflow -c metontiime2.conf run metontiime2.nf -profile docker
```

Run with Singularity/Apptainer:

```bash
nextflow -c metontiime2.conf run metontiime2.nf -profile singularity
```

---

## 12. Important container path warning

The current Docker profile contains a bind mount similar to:

```groovy
containerOptions = '-v /home/:/home'
```

The Singularity profile contains a bind mount similar to:

```groovy
containerOptions = '--bind /home/:/home'
```

This means files under `/home` are visible inside the container.

If your files are stored somewhere else, such as:

```text
/mnt/c/
/mnt/d/
/media/
/scratch/
/data/
external drive paths
HPC storage paths
```

the container may not be able to see them unless you edit the bind mount.

Example for WSL path under `/mnt/d`:

```groovy
containerOptions = '-v /mnt/d:/mnt/d'
```

For Singularity:

```groovy
containerOptions = '--bind /mnt/d:/mnt/d'
```

This is one of the most common container-related failure points.

---

## 13. Example: Zymo demo configuration

For the small Zymo demo dataset, a simplified configuration may use:

```groovy
params {
    workDir = "examples/zymo_demo/raw_fastq"
    sampleMetadata = "examples/zymo_demo/metadata/sample-metadata.tsv"
    resultsDir = "results/zymo_demo"

    dbSequencesFasta = "database/silva/silva-sequences.fasta"
    dbTaxonomyTsv = "database/silva/silva-taxonomy.tsv"
    dbSequencesQza = "db_sequences.qza"
    dbTaxonomyQza = "db_taxonomy.qza"

    classifier = "VSEARCH"

    minReadLength = 1200
    maxReadLength = 1700
    minQual = 10
    extraEndsTrim = 20

    maxNumReads = 50000
    clusteringIdentity = 1.0

    taxaLevelDiversity = 6
    numReadsDiversity = 100

    concatenateFastq = false
    filterFastq = true
    downsampleFastq = true
    importFastq = true
    dataQC = true
    importDb = true
    derepSeq = true
    assignTaxonomy = true
    taxonomyVisualization = true
    collapseTables = true
    filterTaxa = false
    diversityAnalyses = true
}
```

---

## 14. Example: Gili Meno benchmark configuration draft

For a private Gili Meno lake ONT full-length 16S dataset:

```groovy
params {
    workDir = "/path/to/gili_meno/raw_fastq"
    sampleMetadata = "/path/to/gili_meno/metadata/sample-metadata.tsv"
    resultsDir = "/path/to/gili_meno/results"

    dbSequencesFasta = "/path/to/database/silva/silva-sequences.fasta"
    dbTaxonomyTsv = "/path/to/database/silva/silva-taxonomy.tsv"
    dbSequencesQza = "db_sequences.qza"
    dbTaxonomyQza = "db_taxonomy.qza"

    classifier = "VSEARCH"

    minReadLength = 1200
    maxReadLength = 1700
    minQual = 10
    extraEndsTrim = 20

    maxNumReads = 50000
    clusteringIdentity = 0.99

    taxaLevelDiversity = 6
    numReadsDiversity = 500

    concatenateFastq = false
    filterFastq = true
    downsampleFastq = true
    importFastq = true
    dataQC = true
    importDb = true
    derepSeq = true
    assignTaxonomy = true
    taxonomyVisualization = true
    collapseTables = true
    filterTaxa = false
    diversityAnalyses = true
}
```

Before running, confirm:

```text
1. FASTQ files are already demultiplexed
2. File names match sample IDs
3. Metadata table is correct
4. Database paths exist
5. Container bind path includes the data location
```

---

## 15. Common configuration mistakes

### Mistake 1: FASTQ files are outside the container bind path

Symptom:

```text
File exists on host, but pipeline cannot find it inside Docker/Singularity.
```

Fix:

Edit `containerOptions` or move files under the bound directory.

---

### Mistake 2: Metadata sample IDs do not match FASTQ names

Symptom:

```text
QIIME2 metadata-related error
sample not found
metadata mismatch
```

Fix:

Make sure:

```text
sample01.fastq.gz
```

matches:

```text
sample01
```

in `sample-metadata.tsv`.

---

### Mistake 3: Wrong database for marker

Symptom:

```text
Many reads are Unassigned
Taxonomy results look biologically strange
```

Fix:

Use a database matching the marker:

```text
16S → SILVA or Greengenes2
18S → SILVA
ITS → UNITE
```

---

### Mistake 4: Read length thresholds are copied blindly

Symptom:

```text
Too few reads remain after filtering
```

Fix:

Check read length distribution first.

Recommended tools:

```bash
seqkit stats *.fastq.gz
NanoPlot --fastq *.fastq.gz
```

Then adjust:

```groovy
minReadLength
maxReadLength
```

---

### Mistake 5: Diversity sampling depth is too high

Symptom:

```text
QIIME2 diversity analysis fails
Some samples disappear
```

Fix:

Inspect feature table summary first, then lower:

```groovy
numReadsDiversity
```

---

### Mistake 6: `concatenateFastq` mode is wrong

If input is barcode folders:

```text
barcode01/
barcode02/
```

use:

```groovy
concatenateFastq = true
```

If input is already sample-level FASTQ files:

```text
sample01.fastq.gz
sample02.fastq.gz
```

use:

```groovy
concatenateFastq = false
```

---

## 16. Recommended future simplification

The current config should eventually be replaced or wrapped by a simpler user-facing interface.

Proposed future command:

```bash
metontiime-streamline run   --input raw_fastq/   --metadata metadata/sample-metadata.tsv   --database silva-full-length   --marker 16s-full-length   --profile docker   --out results/
```

Proposed future YAML config:

```yaml
input: raw_fastq/
metadata: metadata/sample-metadata.tsv
output: results/

input_mode: fastq_per_sample
marker: 16s_full_length

database:
  mode: qza
  sequences: database/silva/silva-sequences.qza
  taxonomy: database/silva/silva-taxonomy.qza

filtering:
  min_read_length: 1200
  max_read_length: 1700
  min_quality: 10
  trim_ends: 20

taxonomy:
  classifier: VSEARCH
  min_identity: 0.9
  min_query_coverage: 0.8

clustering:
  identity: 0.99

downsampling:
  enabled: true
  max_reads: 50000
  seed: 42

diversity:
  enabled: true
  taxonomic_level: 6
  sampling_depth: 500
```

---

## 17. Practical recommendation

For now, the safest workflow is:

```text
1. Copy an example config
2. Edit only paths, database, filtering, and output settings
3. Leave Docker/Singularity profile untouched unless necessary
4. Run a small demo first
5. Inspect outputs
6. Then run real data
```

Suggested order:

```text
Zymo demo
↓
Gili Meno small subset
↓
Full Gili Meno benchmark
```

---

## 18. Summary

The current `metontiime2.conf` is powerful but too dense for beginners.

MetONTIIME-streamline should make configuration easier by:

```text
1. documenting each parameter clearly
2. providing example configs
3. separating beginner and advanced settings
4. adding input validation
5. creating a wrapper CLI
6. generating configs automatically in the future
```

The first major usability goal is simple:

> New users should not need to understand the entire Nextflow config before running one ONT metabarcoding dataset.
