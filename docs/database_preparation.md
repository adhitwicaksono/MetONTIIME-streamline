# Database Preparation for MetONTIIME-streamline

This document explains where reference database files come from, which database types are commonly used for metabarcoding, and how those files relate to the expected MetONTIIME/QIIME2 inputs.

MetONTIIME-streamline is intended to bridge Oxford Nanopore Technologies (ONT) metabarcoding reads into QIIME2-compatible outputs. Because the pipeline depends on taxonomic assignment, reference database preparation is a critical step.

---

## 1. Why database preparation matters

A metabarcoding pipeline does not identify organisms from reads alone.

It needs a reference database containing:

```text
1. Reference sequences
2. Taxonomic labels for those reference sequences
```

For QIIME2-style analysis, these may appear as:

```text
db-sequences.fasta
db-taxonomy.tsv
```

or as imported QIIME2 artifacts:

```text
db-sequences.qza
db-taxonomy.qza
```

Some workflows may also use pre-trained classifiers:

```text
classifier.qza
```

The correct database depends on the marker region:

| Marker | Common database |
|---|---|
| 16S rRNA | SILVA, Greengenes2 |
| 18S rRNA | SILVA |
| ITS | UNITE |
| Custom marker | Custom FASTA + taxonomy TSV |

---

## 2. Recommended beginner choice

For most beginner ONT metabarcoding projects:

| Target | Recommended starting database |
|---|---|
| Bacteria / Archaea 16S | SILVA full-length or suitable SILVA-derived QIIME2 files |
| Eukaryotic 18S | SILVA 18S / SSU reference files |
| Fungal ITS | UNITE |
| Legacy 16S comparison | Greengenes2 or older Greengenes, depending on project context |
| Local/custom taxa | Custom curated FASTA + taxonomy TSV |

For ONT full-length 16S, avoid blindly using short-read region-specific classifiers unless the marker region matches the data.

---

## 3. What files does MetONTIIME expect?

The original MetONTIIME workflow can use database inputs such as:

```text
dbSequencesFasta
dbTaxonomyTsv
dbSequencesQza
dbTaxonomyQza
```

In plain language:

| Parameter | Meaning |
|---|---|
| `dbSequencesFasta` | Reference sequences in FASTA format |
| `dbTaxonomyTsv` | Taxonomic labels linked to reference sequence IDs |
| `dbSequencesQza` | QIIME2-imported reference sequences |
| `dbTaxonomyQza` | QIIME2-imported reference taxonomy |

A clean local database folder may look like:

```text
database/
├── silva/
│   ├── silva-sequences.fasta
│   ├── silva-taxonomy.tsv
│   ├── silva-sequences.qza
│   └── silva-taxonomy.qza
│
├── unite/
│   ├── unite-sequences.fasta
│   ├── unite-taxonomy.tsv
│   ├── unite-sequences.qza
│   └── unite-taxonomy.qza
│
└── custom/
    ├── custom-sequences.fasta
    ├── custom-taxonomy.tsv
    ├── custom-sequences.qza
    └── custom-taxonomy.qza
```

---

## 4. SILVA database

### Best for

```text
16S rRNA
18S rRNA
SSU rRNA metabarcoding
```

SILVA is commonly used for ribosomal RNA marker gene analysis, especially bacterial/archaeal 16S and eukaryotic 18S/SSU workflows.

### Where to get it

Useful starting points:

```text
QIIME2 data resources:
https://library.qiime2.org/data-resources

SILVA QIIME2 classifiers:
https://www.arb-silva.de/documentation/classifiers/qiime-2/
```

### Notes for ONT data

For ONT full-length 16S, prefer full-length-compatible reference files or classifiers.

Do not automatically use a V3-V4, V4, or other short-region classifier unless your amplicon actually targets that region.

---

## 5. UNITE database

### Best for

```text
Fungal ITS metabarcoding
```

UNITE is centered on the eukaryotic nuclear ribosomal ITS region and is the common reference database for fungal ITS studies.

### Where to get it

Useful starting points:

```text
UNITE homepage:
https://unite.ut.ee/

QIIME2 RESCRIPt get-unite-data documentation:
https://docs.qiime2.org/2024.10/plugins/available/rescript/get-unite-data/

Community-maintained pre-trained UNITE classifiers:
https://github.com/colinbrislawn/unite-train
```

### Notes for ONT data

ITS length can vary substantially among taxa. For ONT ITS analysis, length filtering should be chosen carefully and should not be copied from 16S settings.

---

## 6. Greengenes2

### Best for

```text
16S rRNA studies
legacy-compatible microbiome comparisons
some integrated 16S / shotgun comparative contexts
```

Greengenes2 is a redesigned successor to the older Greengenes database.

### Where to get it

Useful starting points:

```text
q2-greengenes2:
https://github.com/biocore/q2-greengenes2

QIIME2 data resources:
https://library.qiime2.org/data-resources
```

### Notes

Older Greengenes 13_8 is still seen in many older microbiome workflows, but new projects should carefully consider whether Greengenes2 or SILVA is more appropriate.

---

## 7. Custom database

A custom database is useful when:

```text
1. The target organisms are poorly represented in public databases
2. The marker is not standard 16S/18S/ITS
3. The study focuses on local biodiversity
4. The user has curated reference sequences
5. The expected taxa are environmental, rare, or underrepresented
```

A minimal custom database requires:

```text
custom-sequences.fasta
custom-taxonomy.tsv
```

Example FASTA:

```fasta
>seq001
ACGTACGTACGTACGT
>seq002
ACGTACGTACGTACGA
```

Example taxonomy TSV:

```tsv
Feature ID	Taxon
seq001	Bacteria; Proteobacteria; Gammaproteobacteria
seq002	Bacteria; Firmicutes; Bacilli
```

The IDs in the FASTA file must match the IDs in the taxonomy TSV.

---

## 8. Importing FASTA and taxonomy TSV into QIIME2 artifacts

Example QIIME2 import commands:

```bash
qiime tools import   --type 'FeatureData[Sequence]'   --input-path database/custom/custom-sequences.fasta   --output-path database/custom/custom-sequences.qza
```

```bash
qiime tools import   --type 'FeatureData[Taxonomy]'   --input-format HeaderlessTSVTaxonomyFormat   --input-path database/custom/custom-taxonomy.tsv   --output-path database/custom/custom-taxonomy.qza
```

If the taxonomy TSV has a header, the required import format may differ. Always check the format of your taxonomy file.

---

## 9. Suggested MetONTIIME-streamline database modes

In the future, MetONTIIME-streamline should make database handling explicit.

### Mode A — Use existing QIIME2 artifacts

```bash
metontiime-streamline run   --input raw_fastq/   --metadata metadata/sample-metadata.tsv   --db-sequences-qza database/silva/silva-sequences.qza   --db-taxonomy-qza database/silva/silva-taxonomy.qza   --out results/
```

### Mode B — Import FASTA + taxonomy TSV first

```bash
metontiime-streamline prepare-db   --sequences-fasta database/custom/custom-sequences.fasta   --taxonomy-tsv database/custom/custom-taxonomy.tsv   --out database/custom/
```

Then:

```bash
metontiime-streamline run   --input raw_fastq/   --metadata metadata/sample-metadata.tsv   --db-sequences-qza database/custom/custom-sequences.qza   --db-taxonomy-qza database/custom/custom-taxonomy.qza   --out results/
```

### Mode C — Use a named local preset

```bash
metontiime-streamline run   --input raw_fastq/   --metadata metadata/sample-metadata.tsv   --database silva-full-length   --out results/
```

This mode would require the user to configure local database paths once.

---

## 10. Common beginner questions

### Which database should I use for 16S?

Use SILVA or Greengenes2. For environmental microbiome work, SILVA is a common starting point.

### Which database should I use for 18S?

Use SILVA SSU/18S-compatible reference data.

### Which database should I use for fungal ITS?

Use UNITE.

### Can I use the same database for 16S and ITS?

No. 16S and ITS are different marker systems and need different reference databases.

### Can I use short-read QIIME2 classifiers for ONT full-length reads?

Be careful. If the classifier was trained for a short amplicon region such as V4 or V3-V4, it may not be appropriate for full-length ONT reads.

### Do I need `.qza` files?

For QIIME2-based workflows, yes. If you only have FASTA and TSV files, they can be imported into `.qza` artifacts.

### Should database files be committed to GitHub?

Usually no.

Database files can be large and may have their own licenses. Instead, document where to download them and how to place them locally.

---

## 11. Recommended documentation for this repository

The repository should include:

```text
docs/database_preparation.md
docs/input_modes.md
docs/output_files.md
docs/troubleshooting.md
examples/database_layout/
```

The README should include only the short version and link users to this database preparation document.

---

## 12. Suggested README short section

This section can be copied into the main README:

```markdown
## Where do I get the taxonomy database files?

MetONTIIME-streamline requires a marker-gene reference database for taxonomic assignment.

Common choices:

| Marker | Recommended database |
|---|---|
| 16S rRNA | SILVA or Greengenes2 |
| 18S rRNA | SILVA |
| ITS | UNITE |
| Custom marker | Custom FASTA + taxonomy TSV |

The database usually consists of reference sequences and taxonomy labels, either as FASTA/TSV files or as QIIME2 `.qza` artifacts.

See:

```text
docs/database_preparation.md
```

for detailed instructions.
```

---

## 13. Practical recommendation for the Gili Meno benchmark

For the Gili Meno lake ONT dataset, first identify the marker region.

If the dataset is full-length 16S:

```text
Start with SILVA full-length-compatible files.
```

If the dataset is ITS:

```text
Start with UNITE.
```

If the dataset is 18S:

```text
Start with SILVA SSU/18S-compatible files.
```

Before running the full pipeline, record:

```text
database name
database version
download date
source URL
QIIME2 version
import commands used
```

This information should be included in the benchmark report.
