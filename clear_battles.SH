set -euo pipefail
source "$(dirname "$0")/config.sh"

echo "========================================"
echo "  Primal Conquest — Clear Battles"
echo "========================================" 

sudo kubectl delete gameservers --all -n $NAMESPACE --kubeconfig $KUBECONFIG || true