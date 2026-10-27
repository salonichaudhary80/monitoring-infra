#!/usr/bin/env bash
# ------------------------------------------------------------
# destroy.sh  -  ONE CLICK: deletes everything so AWS stops charging
# Run:  ./destroy.sh
# ------------------------------------------------------------
set -e
cd "$(dirname "$0")"
terraform destroy -auto-approve
