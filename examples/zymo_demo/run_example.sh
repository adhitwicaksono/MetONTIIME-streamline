#!/usr/bin/env bash
set -euo pipefail

# Run the Zymo demo from the repository root.
# Edit examples/zymo_demo/config/zymo_demo.example.conf first,
# especially database paths.

nextflow -c examples/zymo_demo/config/zymo_demo.example.conf \
  run metontiime2.nf \
  -profile docker
