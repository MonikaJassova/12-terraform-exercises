#!/usr/bin/env bash
# Regenerates environments/<env>/kubeconfig.yaml for the CCE cluster's EXTERNAL (public EIP) endpoint.
#
# The OTC CCE kubeconfig data source issues a fresh client certificate on every
# read, so this is NOT done by Terraform (a local_file would drift every plan).
# Instead we fetch it on demand and store it in a gitignored file.
#
# Usage:  mise exec -- bash generate-kubeconfig.sh <env>   (env: dev|staging|test)
# Requires: python3 with PyYAML. Run from the project root.
set -euo pipefail

env="${1:-}"
if [[ "$env" != "dev" && "$env" != "staging" && "$env" != "test" ]]; then
  echo "Usage: $0 <dev|staging|test>" >&2
  exit 1
fi
cd "$(dirname "$0")/environments/$env"

raw_kc=$(mise exec -- terraform console <<'EOF'
module.base.kubeconfig
EOF
)
eip=$(mise exec -- terraform console <<'EOF' | tr -d '"'
module.base.cluster_eip
EOF
)

# raw_kc is terraform console's output: the kubeconfig YAML JSON-encoded as a
# quoted string. JSON is valid YAML, so parse the JSON wrapper first, then the YAML.
printf '%s' "$raw_kc" | EIP="$eip" python3 -c '
import json, os, sys, yaml
raw = json.loads(sys.stdin.read().strip())
cfg = yaml.safe_load(raw)
eip = os.environ["EIP"]
user = cfg["users"][0]["name"]
cfg["clusters"] = [{
    "name": "externalCluster",
    "cluster": {"server": f"https://{eip}:5443", "insecure-skip-tls-verify": True},
}]
cfg["contexts"] = [{
    "name": "external",
    "context": {"cluster": "externalCluster", "user": user},
}]
cfg["current-context"] = "external"
with open("kubeconfig.yaml", "w") as f:
    yaml.safe_dump(cfg, f, default_flow_style=False)
os.chmod("kubeconfig.yaml", 0o600)
print(f"Wrote kubeconfig.yaml -> https://{eip}:5443 (context: external)")
'
