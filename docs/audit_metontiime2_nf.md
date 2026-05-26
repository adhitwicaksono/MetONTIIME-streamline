# MetONTIIME2 Nextflow Audit

This document summarizes the first structural audit of `metontiime2.nf` from the **MetONTIIME-streamline** fork.

The purpose of this audit is to understand the current pipeline anatomy before making major changes. The main goal of the fork is not to replace QIIME2 or rewrite MetONTIIME from scratch, but to make the ONT-to-QIIME2 metabarcoding workflow easier to run, inspect, debug, and benchmark.

---

## 1. Audit summary

The current `metontiime2.nf` workflow is scientifically understandable and biologically useful, but its implementation behaves more like a linear Bash pipeline wrapped inside Nextflow than a fully channel-driven Nextflow workflow.

The core logic is reasonable:

```text
ONT FASTQ
   ↓
concatenate/copy FASTQ
   ↓
quality + length filtering
   ↓
optional downsampling
   ↓
QIIME2 import
   ↓
dereplication + de novo clustering
   ↓
taxonomy assignment
   ↓
taxa filtering / table collapsing / visualization
   ↓
diversity analysis
   ↓
QIIME2-compatible outputs
```

However, many processes communicate through files written directly into `params.resultsDir`, rather than passing tracked files through Nextflow channels. This makes the workflow harder to debug, harder to resume safely, and more fragile when input paths, filenames, or intermediate files are not exactly as expected.

---

## 2. Main process map

| Step | Process | Main purpose |
|---:|---|---|
| 1 | `importDb` | Import FASTA + taxonomy TSV into QIIME2 `.qza` database artifacts |
| 2 | `concatenateFastq` | Concatenate barcode-folder FASTQ files or copy existing `.fastq.gz` files |
| 3 | `filterFastq` | Filter reads by quality and length using `NanoFilt`, then trim ends with `seqtk` |
| 4 | `downsampleFastq` | Randomly downsample reads per sample using `seqtk sample` |
| 5 | `importFastq` | Generate QIIME2 manifest and import reads as `sequences.qza` |
| 6 | `dataQC` | Generate `demux_summary.qzv` |
| 7 | `derepSeq` | Dereplicate sequences and cluster de novo using `qiime vsearch` |
| 8 | `assignTaxonomy` | Assign taxonomy using BLAST or VSEARCH |
| 9 | `filterTaxa` | Optionally retain taxa of interest |
| 10 | `taxonomyVisualization` | Generate QIIME2 taxa barplots |
| 11 | `collapseTables` | Collapse feature table across taxonomy levels and export BIOM/TSV |
| 12 | `diversityAnalyses` | Run non-phylogenetic diversity analyses |

---

## 3. Pipeline behavior

### 3.1 Database preparation

The `importDb` process imports reference database files into QIIME2 artifacts.

Expected database inputs may include:

```text
dbSequencesFasta
dbTaxonomyTsv
dbSequencesQza
dbTaxonomyQza
```

Observed issue:

- The database mode can be confusing.
- If database import is skipped, downstream steps may still expect `.qza` database files in a specific output directory.
- The user-facing distinction between “I have FASTA + TSV” and “I already have QIIME2 `.qza` artifacts” should be made clearer.

Recommended streamline behavior:

```text
Case A: user provides FASTA + TSV → import into QIIME2 artifacts
Case B: user provides QZA + QZA → use or copy existing artifacts
Case C: user provides named preset → use configured local database paths
```

---

### 3.2 FASTQ handling

The `concatenateFastq` process supports at least two implicit input modes:

```text
1. Barcode-folder mode
2. Pre-existing FASTQ-per-sample mode
```

Barcode-folder mode appears to expect folders such as:

```text
barcode01/
barcode02/
barcode03/
```

FASTQ-per-sample mode expects files such as:

```text
sample01.fastq.gz
sample02.fastq.gz
sample03.fastq.gz
```

Observed issue:

- The pipeline uses `params.workDir` as the input FASTQ directory.
- This is confusing because “workDir” in Nextflow usually refers to the internal working directory.
- The FASTQ detection logic is brittle.
- Plain `.fastq` files may not always be handled consistently.
- Spaces in filenames may break shell commands.

Recommended streamline behavior:

Expose explicit input modes:

```text
--input-mode barcode_dirs
--input-mode fastq_per_sample
--input-mode single_fastq
```

And rename user-facing `workDir` to:

```text
--input
```

or:

```text
--fastq-dir
```

---

### 3.3 Quality and length filtering

The `filterFastq` process performs quality and length filtering, apparently using `NanoFilt`, followed by trimming with `seqtk`.

Important parameters include:

```text
minReadLength
maxReadLength
minQual
extraEndsTrim
```

Observed issue:

- These parameters are biologically important and marker-dependent.
- Users need better guidance for full-length 16S, 18S, ITS, and custom markers.
- If values are too strict, too few reads may remain.
- If values are too permissive, noisy reads may reduce downstream taxonomic accuracy.

Recommended documentation:

Provide marker-specific example ranges, clearly labeled as starting points rather than universal defaults.

Example starter values for full-length 16S:

```text
minReadLength       = 1200
maxReadLength       = 1700
minQual             = 10
extraEndsTrim       = 0
```

---

### 3.4 Downsampling

The `downsampleFastq` process uses `seqtk sample`.

Observed issue:

```bash
seqtk sample input.fastq.gz N
```

This performs random downsampling, but no seed is specified.

This is a problem for benchmarking because repeated runs may produce slightly different outputs.

Recommended patch:

```bash
seqtk sample -s ${params.seed} input.fastq.gz ${params.maxNumReads}
```

Recommended new parameter:

```text
seed = 42
```

Recommended CLI flag later:

```text
--seed 42
```

Priority:

```text
High for benchmark reproducibility
```

---

### 3.5 QIIME2 import

The `importFastq` process creates a QIIME2 manifest and imports filtered reads as QIIME2 artifacts.

Observed issue:

- Metadata may be auto-generated if missing.
- Auto-generation is convenient but risky if done silently.
- Serious microbiome analysis should encourage proper metadata.

Recommended behavior:

Auto-metadata generation should be explicit.

Possible future commands:

```bash
metontiime-streamline init-metadata --input raw_fastq/
```

or:

```bash
metontiime-streamline run --auto-metadata
```

The tool should clearly report:

```text
WARNING: Metadata file was missing. A minimal metadata file was generated.
```

---

### 3.6 Dereplication and clustering

The `derepSeq` process runs QIIME2/VSEARCH dereplication and clustering.

Likely outputs include:

```text
table.qza
rep-seqs.qza
```

Observed issue:

- The biological logic is useful and should be preserved.
- Output paths and names should be documented clearly.
- Clustering identity should be user-visible and benchmarked.

Important parameter:

```text
clusteringIdentity
```

Potential starter value:

```text
0.97
```

But this should remain adjustable because ONT error profiles and marker regions may vary.

---

### 3.7 Taxonomy assignment

The `assignTaxonomy` process supports taxonomy assignment, likely using BLAST or VSEARCH depending on configuration.

Important parameters include:

```text
classifier
minIdentity
minQueryCoverage
```

Observed issue:

- Database choice, marker choice, and identity thresholds strongly affect classification.
- Too many unclassified reads may result from poor read quality, wrong database, strict thresholds, or underrepresented environmental taxa.

Recommended documentation:

Add troubleshooting for:

```text
Too many unclassified reads
```

Possible causes:

```text
wrong marker database
wrong primer/amplicon target
poor read quality
overly strict identity threshold
incomplete database
non-target amplification
environmental organisms poorly represented in database
```

---

### 3.8 Taxa filtering

The `filterTaxa` process optionally filters the table to keep taxa of interest.

Observed issue:

Parameters such as `taxaOfInterest` may contain spaces, semicolons, brackets, or other characters that are not safe for shell commands or output filenames.

Example risky value:

```text
Bacteria; Proteobacteria
```

This may produce problematic filenames or shell parsing issues.

Recommended behavior:

Keep two representations:

```text
raw query: "Bacteria; Proteobacteria"
safe filename slug: bacteria_proteobacteria
```

Recommended output naming:

```text
table-taxa-bacteria_proteobacteria.qza
```

Avoid output names like:

```text
table-Bacteria; Proteobacteria.qza
```

Priority:

```text
Medium-high
```

---

### 3.9 Taxonomy visualization

The `taxonomyVisualization` process generates QIIME2 taxa barplots.

Likely output:

```text
taxa-barplot.qzv
```

Observed issue:

- Useful output, but README should clearly tell users how to open `.qzv` files.

Recommended documentation:

```bash
qiime tools view taxa-barplot.qzv
```

or:

```text
https://view.qiime2.org/
```

---

### 3.10 Table collapsing and export

The `collapseTables` process collapses feature tables by taxonomic level and exports tables.

Important parameter:

```text
taxaLevelDiversity
```

Likely outputs include:

```text
collapsed tables
BIOM files
TSV files
```

Observed issue:

- The README should distinguish QIIME2 artifacts (`.qza`), visualizations (`.qzv`), and exported plain-text/BIOM files.
- Exported outputs are important for downstream use outside QIIME2.

Recommended output organization:

```text
results/
├── qza/
├── qzv/
├── exports/
├── logs/
└── reports/
```

---

### 3.11 Diversity analysis

The `diversityAnalyses` process runs non-phylogenetic diversity analyses.

Important parameter:

```text
numReadsDiversity
```

Observed issue:

There appears to be a likely output path bug in the `filterTaxa = true` branch.

The filtered-taxa branch creates a directory containing:

```text
taxa-${params.taxaOfInterest}-samplingDepth-${params.numReadsDiversity}-level${params.taxaLevelDiversity}
```

But one Bray-Curtis output path appears to omit the `taxa-${params.taxaOfInterest}` part.

Suspicious path:

```text
diversityAnalyses/samplingDepth-${params.numReadsDiversity}-level${params.taxaLevelDiversity}/bray-curtis-distance-matrix.qza
```

Likely intended path:

```text
diversityAnalyses/taxa-${params.taxaOfInterest}-samplingDepth-${params.numReadsDiversity}-level${params.taxaLevelDiversity}/bray-curtis-distance-matrix.qza
```

Recommended first code patch:

```text
fix: correct bray-curtis output path in filtered diversity analysis
```

Priority:

```text
High, but should be verified before patching
```

---

## 4. Parameter audit draft

| Parameter | Likely meaning | User-facing? | Streamline action |
|---|---|---:|---|
| `workDir` | Input FASTQ directory | Yes | Rename concept to `--input` |
| `resultsDir` | Output directory | Yes | Keep as `--out` |
| `sampleMetadata` | Metadata TSV | Yes | Validate and document |
| `dbSequencesFasta` | Database sequences FASTA | Yes | Use only in FASTA+TSV database mode |
| `dbTaxonomyTsv` | Database taxonomy TSV | Yes | Use only in FASTA+TSV database mode |
| `dbSequencesQza` | Database sequences QZA | Yes | Use in QZA database mode |
| `dbTaxonomyQza` | Database taxonomy QZA | Yes | Use in QZA database mode |
| `classifier` | Taxonomy assignment method | Yes | Restrict to supported choices |
| `maxNumReads` | Downsampling reads per sample | Yes | Add seed for reproducibility |
| `minReadLength` | Minimum read length | Yes | Marker-specific guidance |
| `maxReadLength` | Maximum read length | Yes | Marker-specific guidance |
| `minQual` | Minimum read quality | Yes | Document ONT-specific impact |
| `extraEndsTrim` | Extra trimming at read ends | Yes | Keep but explain clearly |
| `clusteringIdentity` | VSEARCH clustering identity | Yes | Benchmark-sensitive |
| `minIdentity` | Taxonomy minimum identity | Yes | Database-sensitive |
| `minQueryCoverage` | Taxonomy minimum query coverage | Yes | Database-sensitive |
| `taxaOfInterest` | Optional taxa filter | Yes | Sanitize filename slug |
| `taxaLevelDiversity` | Taxonomic level for diversity/table collapse | Yes | Explain levels |
| `numReadsDiversity` | Sampling depth for diversity | Yes | Validate against feature table depth |

---

## 5. Major pain points

### 5.1 Side-effect-heavy execution

Most processes write files into `params.resultsDir`, then downstream processes assume those files exist.

Problem:

```text
Nextflow is not fully tracking data products.
```

Impact:

```text
Harder debugging
Fragile resume behavior
Hidden file dependency problems
Missing files discovered too late
```

Recommended long-term fix:

Gradually refactor process outputs to use `path` outputs and real channels.

Priority:

```text
Long-term
```

---

### 5.2 Ambiguous input model

The pipeline supports different input styles, but they are not clearly exposed.

Recommended immediate documentation:

```text
Input mode 1: barcode directories
Input mode 2: FASTQ per sample
Input mode 3: single FASTQ
```

Priority:

```text
High
```

---

### 5.3 Configuration burden

The user must manually edit `metontiime2.conf`.

This is one of the main reasons the fork exists.

Recommended medium-term fix:

Create a wrapper that:

```text
1. validates input
2. generates a clean local config
3. runs Nextflow
4. writes a run summary
```

Priority:

```text
Core fork objective
```

---

### 5.4 Reproducibility issue in downsampling

Downsampling without a fixed seed makes benchmark comparisons unstable.

Recommended fix:

```text
Add seed parameter
```

Priority:

```text
High
```

---

### 5.5 Silent metadata generation

Auto-generating metadata is useful but should be explicit.

Recommended fix:

```text
Make auto-metadata an explicit option
```

Priority:

```text
Medium
```

---

### 5.6 Unsafe taxa names in filenames

Taxa strings may contain shell-unsafe or filename-unsafe characters.

Recommended fix:

```text
Sanitize taxa labels into safe filename slugs
```

Priority:

```text
Medium-high
```

---

## 6. Streamlining priorities

### Priority 1 — Documentation and audit

Create:

```text
docs/audit_metontiime2_nf.md
docs/input_modes.md
docs/output_files.md
docs/database_modes.md
docs/troubleshooting.md
```

### Priority 2 — Safe small bug patches

Patch likely path issues and obvious shell fragility without changing biological behavior.

Candidate first patch:

```text
fix: correct bray-curtis output path in filtered diversity analysis
```

### Priority 3 — Reproducibility

Add:

```text
params.seed
```

Use it in downsampling:

```bash
seqtk sample -s ${params.seed}
```

### Priority 4 — Input validation

Add a helper script to check:

```text
FASTQ files exist
metadata exists
sample IDs match FASTQ names
database files exist
filenames contain no spaces
output directory is writable
```

### Priority 5 — Wrapper CLI

Develop a user-facing command such as:

```bash
metontiime-streamline run   --input raw_fastq/   --metadata metadata/sample-metadata.tsv   --db-sequences database/db-sequences.qza   --db-taxonomy database/db-taxonomy.qza   --marker 16s-full-length   --profile docker   --out results/
```

---

## 7. Suggested first commits

### Commit 1

```bash
git add docs/audit_metontiime2_nf.md
git commit -m "docs: add audit of MetONTIIME2 Nextflow workflow"
```

### Commit 2

```bash
git add README.md
git commit -m "docs: rewrite README for MetONTIIME-streamline usability"
```

### Commit 3

```bash
git add metontiime2.nf
git commit -m "fix: correct filtered diversity bray-curtis output path"
```

Only do Commit 3 after confirming the suspicious path in the current script.

---

## 8. Gili Meno benchmark implications

The Gili Meno lake ONT FASTQ dataset can be used as the first real benchmark dataset for the fork.

Before running the full pipeline, benchmark preparation should include:

```text
1. Count FASTQ files
2. Check whether reads are already demultiplexed
3. Check marker target
4. Confirm barcode/adaptor removal status
5. Run basic read QC
6. Check read length distribution
7. Decide min/max length thresholds
8. Decide quality threshold
9. Prepare metadata TSV
10. Prepare database files
```

Recommended pre-pipeline QC tools:

```bash
seqkit stats *.fastq.gz
NanoPlot --fastq *.fastq.gz
```

Important benchmark questions:

```text
Can original MetONTIIME run successfully?
Can MetONTIIME-streamline reproduce equivalent outputs?
How many reads survive filtering?
How many features are generated?
How many reads are classified?
Are outputs valid QIIME2 artifacts?
Can taxa barplots and diversity analyses be generated?
```

---

## 9. Current verdict

MetONTIIME is valuable because it already connects ONT metabarcoding data with QIIME2-style outputs.

However, the current implementation is:

```text
scientifically useful
but operationally fragile
```

The best role for MetONTIIME-streamline is therefore:

```text
documentation + validation + wrapper first
internal refactor later
```

The fork should prioritize usability, reproducibility, and benchmark clarity before attempting a full workflow rewrite.

In short:

> MetONTIIME-streamline should tame the existing pipeline before replacing its organs.
