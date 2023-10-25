#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

export TERM=xterm

export VULN_CLUSTER_NAME="vulnerable-cluster"
export SAFE_CLUSTER_NAME="safe-128"
export VULN_CLUSTER_VERSION="1.27.3-gke.100"
export SAFE_CLUSTER_VERSION="1.28.2-gke.1157000"
export PROJECT="gcastle-testing-402921"
export ZONE="us-central1-c"
export REGION="us-central1"

DEMOMAGIC="demo-magic.sh"

if [ ! -f $DEMOMAGIC ]; then
  curl -OsS -L https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh 
  chmod a+x demo-magic.sh
fi

. ./demo-magic.sh
# Uncomment to turn off command typing.
#TYPE_SPEED=""
#DEMO_PROMPT="compromised_node# "
# Turns out the white defined in demo-magic renders a little grey.
DEMO_CMD_COLOR=$COLOR_RESET
clear
echo ""
echo ""


