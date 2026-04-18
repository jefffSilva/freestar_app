#!/usr/bin/env bash
# Resolves YOUR_GITHUB_ORG in infra/main.tf for Terraform git module sources.
# Priority: repo Variable TERRAFORM_MODULES_GITHUB_ORG, else github.repository_owner (same GitHub user/org as this repo).
set -euo pipefail

if ! grep -q 'YOUR_GITHUB_ORG' main.tf 2>/dev/null; then
  exit 0
fi

org="${TERRAFORM_MODULES_GITHUB_ORG:-}"
if [ -z "${org}" ]; then
  org="${GITHUB_REPO_OWNER:-}"
fi

if [ -z "${org}" ]; then
  echo "::error title=Terraform modules::Set Actions Variable TERRAFORM_MODULES_GITHUB_ORG (modules in another org) or replace YOUR_GITHUB_ORG in infra/main.tf"
  exit 1
fi

sed -i.bak "s/YOUR_GITHUB_ORG/${org}/g" main.tf
echo "::notice title=Terraform modules::Using GitHub org \"${org}\" for freestar_modules sources"
