#!/usr/bin/env bash
# ------------------------------------------------------------
# deploy.sh  -  ONE CLICK: builds AWS + installs all software
# Run:  ./deploy.sh
# (Terraform builds the infrastructure and then runs Ansible by itself.)
# ------------------------------------------------------------
set -e
cd "$(dirname "$0")"

terraform init -input=false
terraform apply -auto-approve

echo ""
echo "Done! Open Grafana (user: admin):"
terraform output -raw grafana_url
echo ""
