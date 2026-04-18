#!/usr/bin/env bash
set -euo pipefail

# Remote state on GCS when TF_STATE_BUCKET is set; otherwise local state (plan-only / bootstrap).
if [ -n "${TF_STATE_BUCKET:-}" ]; then
  prefix="${TF_STATE_PREFIX:-freestar/infra}"
  terraform init \
    -backend-config="bucket=${TF_STATE_BUCKET}" \
    -backend-config="prefix=${prefix}"
else
  terraform init -backend=false
fi
