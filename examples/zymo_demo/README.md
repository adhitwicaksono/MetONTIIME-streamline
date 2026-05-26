# Zymo Demo Dataset

This folder contains a small example dataset structure for testing **MetONTIIME-streamline**.

The demo FASTQ file used by the original repository is:

```text
Zymo-GridION-EVEN-BB-SN_sup_pass_filtered_27F_1492Rw_1000_reads.fastq.gz
```

From the filename, this appears to be a small Oxford Nanopore GridION full-length 16S rRNA mock-community dataset using the 27F/1492R primer pair and containing 1000 reads.

This example is intended as a lightweight smoke test, not as a full biological benchmark.

---

## Expected folder structure

```text
examples/
└── zymo_demo/
    ├── raw_fastq/
    │   └── Zymo-GridION-EVEN-BB-SN_sup_pass_filtered_27F_1492Rw_1000_reads.fastq.gz
    ├── metadata/
    │   └── sample-metadata.tsv
    ├── config/
    │   └── zymo_demo.example.conf
    └── README.md
```

---

## Moving the demo FASTQ into this folder

If the demo FASTQ is still in the repository root, move it with:

```bash
mkdir -p examples/zymo_demo/raw_fastq

git mv "Zymo-GridION-EVEN-BB-SN_sup_pass_filtered_27F_1492Rw_1000_reads.fastq.gz" \
  examples/zymo_demo/raw_fastq/
```

Then commit the move:

```bash
git add examples/zymo_demo
git commit -m "chore: organize Zymo demo dataset"
```

---

## Metadata

The included metadata file contains one sample:

```tsv
sample-id\tsample-name\tsample-type\tdescription
Zymo-GridION-EVEN-BB-SN_sup_pass_filtered_27F_1492Rw_1000_reads\tZymo_mock_community\tmock_community\tSmall ONT GridION full-length 16S demo dataset
```

The `sample-id` matches the FASTQ filename without the `.fastq.gz` suffix.

---

## Database requirement

This demo still requires a suitable 16S reference database.

For full-length 16S, use a SILVA-compatible database or another properly prepared 16S reference database.

Database preparation is described in:

```text
docs/database_preparation.md
```

Expected database artifacts for this example:

```text
database/silva/silva-sequences.qza
database/silva/silva-taxonomy.qza
```

These paths are placeholders in the example config and should be edited for your local machine.

---

## Running the example

From the repository root:

```bash
nextflow -c examples/zymo_demo/config/zymo_demo.example.conf \
  run metontiime2.nf \
  -profile docker
```

For Singularity/Apptainer:

```bash
nextflow -c examples/zymo_demo/config/zymo_demo.example.conf \
  run metontiime2.nf \
  -profile singularity
```

---

## Expected outputs

The example should produce output under:

```text
results/zymo_demo/
```

Important folders may include:

```text
results/zymo_demo/importFastq/
results/zymo_demo/dataQC/
results/zymo_demo/derepSeq/
results/zymo_demo/assignTaxonomy/
results/zymo_demo/taxonomyVisualization/
results/zymo_demo/collapseTables/
results/zymo_demo/diversityAnalyses/
```

Important QIIME2 artifacts and visualizations may include:

```text
sequences.qza
demux_summary.qzv
table.qza
rep-seqs.qza
taxonomy.qza
taxonomy.qzv
taxa-bar-plots.qzv
```

---

## Notes

This example is designed for testing whether the workflow can run successfully.

For real benchmarking, use a larger dataset with documented metadata, database version, read statistics, and expected output summaries.

The Gili Meno lake ONT dataset is planned as a private real-world benchmark dataset for MetONTIIME-streamline.
