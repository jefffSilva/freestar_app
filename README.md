# Freestar app (Cloud Run + CI/CD)

Minimal Node HTTP service, Docker image, Terraform under `infra/`, and GitHub Actions for **Terraform** and **Cloud Run deploy**.

Authentication from GitHub Actions to Google Cloud must use either:

- **Workload Identity Federation** (recommended — no JSON keys in GitHub), or  
- **`credentials_json`** (long‑lived service account key — avoid if possible).

If `google-github-actions/auth` fails with:

> must specify exactly one of `workload_identity_provider` or `credentials_json`

then **`GCP_WORKLOAD_IDENTITY_PROVIDER`** or **`GCP_DEPLOYER_SERVICE_ACCOUNT`** (for deploy) / **`GCP_TERRAFORM_SERVICE_ACCOUNT`** (for Terraform) are **missing or empty** in the repository **Variables**. Repository **Variables** are **not** passed to workflows from **forks** (including many Dependabot PRs), so auth will fail there unless you use another approach.

---

## Recommended: Workload Identity Federation (GitHub → GCP)

Do this once per GCP project (you can reuse the same pool/provider for multiple service accounts).

### 1. Prerequisites

- [Google Cloud SDK](https://cloud.google.com/sdk) (`gcloud`) installed and authenticated (`gcloud auth login` and `gcloud config set project YOUR_PROJECT_ID`).
- Billing enabled on the project if required by APIs.

Enable APIs:

```bash
export PROJECT_ID="YOUR_GCP_PROJECT_ID"

gcloud services enable iamcredentials.googleapis.com sts.googleapis.com iam.googleapis.com cloudresourcemanager.googleapis.com --project="${PROJECT_ID}"
```

### 2. Workload Identity Pool and OIDC provider

Pick a pool id (example: `github-actions`) and provider id (example: `github`). Use **global** location.

```bash
export PROJECT_ID="YOUR_GCP_PROJECT_ID"
export PROJECT_NUMBER="$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)')"
export POOL_ID="github-actions"
export PROVIDER_ID="github"

gcloud iam workload-identity-pools create "${POOL_ID}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="GitHub Actions"

gcloud iam workload-identity-pools providers create-oidc "${PROVIDER_ID}" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="${POOL_ID}" \
  --display-name="GitHub OIDC" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner"
```

### 3. Service accounts for CI

Create **two** service accounts so deploy and Terraform permissions stay separable (you may use one SA for demos if you accept broader IAM).

**Deploy (build image, push Artifact Registry, deploy Cloud Run)**

```bash
export DEPLOYER_SA="github-deployer@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud iam service-accounts create github-deployer \
  --project="${PROJECT_ID}" \
  --display-name="GitHub Actions deploy"

# Grant roles your pipelines need (adjust to your org’s least privilege).
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${DEPLOYER_SA}" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${DEPLOYER_SA}" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${DEPLOYER_SA}" \
  --role="roles/iam.serviceAccountUser"
```

**Terraform (plan/apply)**

```bash
export TF_SA="github-terraform@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud iam service-accounts create github-terraform \
  --project="${PROJECT_ID}" \
  --display-name="GitHub Actions Terraform"

# Broad starting role for a sandbox; tighten for production (custom role / narrower grants).
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${TF_SA}" \
  --role="roles/editor"

# If Terraform uses a GCS backend for state:
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${TF_SA}" \
  --role="roles/storage.objectAdmin"
```

Create your state bucket separately and scope `storage.objectAdmin` to that bucket if you prefer least privilege.

### 4. Allow GitHub to impersonate each service account

Restrict **`principalSet`** to **this repository only** (replace `GITHUB_ORG` and `REPO_NAME`, e.g. `freestar_app`).

```bash
export GITHUB_ORG="YOUR_GITHUB_ORG_OR_USER"
export REPO_NAME="freestar_app"

export REPO_BINDING="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/attribute.repository/${GITHUB_ORG}/${REPO_NAME}"

gcloud iam service-accounts add-iam-policy-binding "${DEPLOYER_SA}" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="${REPO_BINDING}"

gcloud iam service-accounts add-iam-policy-binding "${TF_SA}" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="${REPO_BINDING}"
```

If you need **only** the `main` branch, use an **attribute condition** on the pool provider or a tighter principal (see Google’s “Configure attribute conditions” for WIF). The snippet above allows any ref from that repository; tighten for production.

### 5. Values to copy into GitHub

**Workload Identity Provider resource name** (full path — this is what `GCP_WORKLOAD_IDENTITY_PROVIDER` must be):

```bash
echo "projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/providers/${PROVIDER_ID}"
```

In GitHub: **Settings → Secrets and variables → Actions → Variables** (not Secrets, unless you prefer Secrets for these):

| Variable | Example | Used by |
|----------|---------|---------|
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | `projects/123456789/locations/global/workloadIdentityPools/github-actions/providers/github` | Deploy + Terraform workflows |
| `GCP_DEPLOYER_SERVICE_ACCOUNT` | `github-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com` | `.github/workflows/deploy-cloud-run.yml` |
| `GCP_TERRAFORM_SERVICE_ACCOUNT` | `github-terraform@YOUR_PROJECT_ID.iam.gserviceaccount.com` | `.github/workflows/terraform.yml` |

**Deploy / runtime configuration (Variables):**

| Variable | Purpose |
|----------|---------|
| `GCP_PROJECT_ID` | GCP project id |
| `GCP_REGION` | Region (e.g. `us-central1`) |
| `CLOUD_RUN_SERVICE_NAME` | Cloud Run service name |
| `ARTIFACT_REGISTRY_REPO` | Artifact Registry Docker repo id |
| `TF_STATE_BUCKET` | Optional; GCS bucket for Terraform state |
| `TF_STATE_PREFIX` | Optional; default `freestar/infra` in init script |

Workflows already set `permissions: id-token: write` where OIDC is required.

---

## Alternative: JSON key (`credentials_json`)

Only if you cannot use WIF. Create a service account key in GCP, store the **entire JSON** in a GitHub **Secret**, and change the auth step to:

```yaml
- uses: google-github-actions/auth@v2
  with:
    credentials_json: ${{ secrets.GCP_CREDENTIALS_JSON }}
```

Prefer **Workload Identity Federation** so long‑lived keys are not stored in GitHub.

---

## References

- [Workload Identity Federation with GitHub Actions](https://cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines)  
- [`google-github-actions/auth`](https://github.com/google-github-actions/auth)
