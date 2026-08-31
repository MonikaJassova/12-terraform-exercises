### This project is for the Devops Bootcamp Exercise for "Infrastructure as Code with Terraform"

Covered:
- IaC setup for deploying managed K8s clusters with 3 nodes (CCE with autoscaler on T Cloud Public) and MySQL DB (3 replicas with persistent volumes using Helm) across dev, staging, and test environments using Terraform
- A multi-environment configuration with separate backends, variables, and state files per environment
- Remote TF backend configured with OBS bucket on TCP
- Jenkins pipeline for infrastructure provisioning on a selected env

## Directory structure

```
.
├── modules/
│   └── base/                # shared module — all OTC resources
│       ├── versions.tf
│       ├── variables.tf
│       ├── vpc.tf           # VPC, subnets, EIPs, NAT, security groups
│       ├── cce-cluster.tf   # CCE cluster, node pool, addons, data sources
│       └── outputs.tf       # cluster_id, cluster_eip, kubeconfig, project_id
├── environments/
│   ├── dev/                 # env_prefix=dev,  CIDR 10.0.x,  k8s svc 10.83.0.0/16
│   ├── staging/             # env_prefix=staging, CIDR 10.1.x,  k8s svc 10.84.0.0/16
│   └── test/                # env_prefix=test, CIDR 10.2.x,  k8s svc 10.85.0.0/16
├── Jenkinsfile              # parameterized pipeline (ENV: dev/staging/test)
├── mise.toml                # pinned tool versions (terraform, etc.), non-sensitive environment variables
├── .env                     # copied from .env.example, sensitive environment variables loaded by mise.toml  
└── .gitignore
```

Each environment directory contains:

| File | Purpose |
|------|---------|
| `providers.tf` | `terraform {}` block (backend, `required_providers`), OTC / helm provider blocks |
| `variables.tf` | Environment-specific variable defaults (env_prefix, CIDRs, key pair, svc IP range) |
| `main.tf` | Calls `module "base"` with the env's variables |
| `mysql.tf` | `helm_release` for MySQL (depends on `module.base`) |
| `mysql-values.yaml` | Per-env MySQL Helm values (root password, database name, credentials) |

## Environments

| Env | env_prefix | VPC CIDR | Private subnets | Public subnets | k8s svc IP range | MySQL credentials |
|-----|-----------|----------|-----------------|----------------|-----------------|-------------------|
| dev | `dev` | `10.0.0.0/16` | `10.0.1–3.0/24` | `10.0.4–6.0/24` | `10.83.0.0/16` | `dev-root-pass` / `dev-app-db` |
| staging | `staging` | `10.1.0.0/16` | `10.1.1–3.0/24` | `10.1.4–6.0/24` | `10.84.0.0/16` | `staging-root-pass` / `staging-app-db` |
| test | `test` | `10.2.0.0/16` | `10.2.1–3.0/24` | `10.2.4–6.0/24` | `10.85.0.0/16` | `test-root-pass` / `test-app-db` |

All environments use:
- OTC region `eu-de`
- Node flavor `s3.large.2` (smallest available), 3 initial nodes, auto-scaling 1–4
- CCE cluster flavor `cce.s1.small`
- Key pair `KeyPair-mjassova2`
- MySQL: 1 primary + 2 secondaries, Bitnami 8.0.30, all replicas with CSI-disk persistent volumes

## Prerequisites

- Terraform >= 1.3 (managed via `mise`)
- OTC credentials set as environment variables:
  - `OS_ACCESS_KEY`
  - `OS_SECRET_KEY`
  - `OS_REGION=eu-de`
  - `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` — same OTC keys, used by the TF s3 backend for the OBS state bucket
- `python3` with PyYAML (for `generate-kubeconfig.sh`)

## Deploying an environment

All commands are run from the repo root and use `mise exec` to pick up the pinned Terraform and injected credentials.

### 1. Init

```bash
mise exec -- terraform -chdir=environments/dev init
```

Run once per environment. Downloads provider plugins and connects to the remote OBS state backend (see [State](#state)).

### 2. Plan

```bash
mise exec -- terraform -chdir=environments/dev plan
```

### 3. Apply

```bash
mise exec -- terraform -chdir=environments/dev apply --auto-approve
```

A single apply creates the VPC, subnets, EIPs, NAT gateway, security groups, CCE cluster, node pool, and the autoscaler addon (coredns and everest are pre-installed by CCE), and then deploys the MySQL Helm release. No pre-step is needed on a fresh environment: the helm provider reads a fresh client certificate from the CCE kubeconfig data source during the apply.

### 4. Generate kubeconfig (for kubectl only)

The script below is only needed for kubectl access (local verification).

```bash
mise exec -- bash generate-kubeconfig.sh dev
```

This writes `environments/dev/kubeconfig.yaml` (gitignored) pointing at the cluster's external EIP on port 5443. On subsequent deploys run it only when the file is lost or its client certificate has expired.

### 5. Verify

```bash
# check pods (mise does not pass the `KUBECONFIG=...` prefix through, so run kubectl inside a shell)
mise exec -- sh -c 'KUBECONFIG=environments/dev/kubeconfig.yaml kubectl get pods'

# run a test query
mise exec -- sh -c 'KUBECONFIG=environments/dev/kubeconfig.yaml kubectl exec mysql-release-primary-0 -- mysql -u dev-user -pdev-pass dev-app-db -e "SELECT 1+1;"'
```

Replace `dev` with `staging` or `test` and use the matching credentials from the table above.

### 6. Destroy (optional)

```bash
mise exec -- terraform -chdir=environments/dev destroy --auto-approve
```

## Running via Jenkins

The `Jenkinsfile` takes an `ENV` parameter (`dev`, `staging`, or `test`) and runs:

```
terraform -chdir=environments/${ENV} init
terraform -chdir=environments/${ENV} apply --auto-approve
```

The pipeline expects the Jenkins credentials `jenkins_tcp_access_key_id` and `jenkins_tcp_secret_access_key` to be configured and Terraform to be installed.

## State

All environments use the **remote** S3 backend pointing at the OBS bucket `myapp-tf-exercises-tfstate-obs-bucket` (region `eu-de`, private access only, versioning enabled). Each environment keeps its state under its own key in the same bucket:

| Env | State key | Lock key |
|-----|-----------|----------|
| dev | `dev/terraform.tfstate` | `dev/terraform.tfstate.tflock` |
| staging | `staging/terraform.tfstate` | `staging/terraform.tfstate.tflock` |
| test | `test/terraform.tfstate` | `test/terraform.tfstate.tflock` |

Backend block (in each env's `providers.tf`):

```hcl
backend "s3" {
  bucket                      = "myapp-tf-exercises-tfstate-obs-bucket"
  key                         = "dev/terraform.tfstate"   # per env: dev / staging / test
  region                      = "eu-de"
  endpoints = {
    s3 = "https://obs.eu-de.otc.t-systems.com/"
  }
  use_path_style              = true
  use_lockfile                = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_region_validation      = true
  skip_metadata_api_check     = true
  skip_s3_checksum            = true
}
```

- Credentials: the backend uses the standard AWS env-var chain — `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` (the same OTC access key; provided by `.env` via `mise.toml` locally and by Jenkins credentials in CI). No keys are stored in the configuration.
- Locking: `use_lockfile` enables native S3 state locking; concurrent `plan`/`apply` on the same environment are serialized via the lock object.
- **Terraform >= 1.11.2** bundles an AWS SDK that adds optional CRC32 checksums to uploads, which OBS does not handle correctly (corrupted state/lock objects). `mise.toml` and the `Jenkinsfile` therefore set `AWS_REQUEST_CHECKSUM_CALCULATION=when_required` and `AWS_RESPONSE_CHECKSUM_VALIDATION=when_required` (see the [OTC provider backends guide](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/guides/backends)).

## Everest CSI Driver

Since K8s 1.23, an additional CSI driver is required to provision persistent volumes. On TCP, Kubernetes volumes attach to EVS volumes. The Everest CSI driver is responsible for handling EVS storage; on this TCP CCE it is a required addon pre-installed with the cluster, so PVCs bind out of the box and Terraform does not deploy it (the addon create API returns 409 for already-installed addons — see `modules/base/cce-cluster.tf`).
