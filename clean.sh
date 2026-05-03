#!/bin/bash
set -uo pipefail   # no -e so every step attempts even if previous fails

source "$(dirname "$0")/config.sh"

echo "========================================"
echo "  Primal Conquest — Full Clean"
echo "========================================"


# ── Delete all resources in the game namespace ────────────────────
echo ""
echo ">>> Deleting all resources in namespace '$NAMESPACE'..."
kubectl delete all --all -n "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null || true

echo ">>> Deleting PersistentVolumeClaims..."
kubectl delete pvc --all -n "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null || true

echo ">>> Deleting Secrets..."
kubectl delete secret --all -n "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null || true

echo ">>> Deleting ConfigMaps..."
kubectl delete configmap --all -n "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null || true

echo ">>> Deleting ServiceAccounts..."
kubectl delete serviceaccount --all -n "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null || true

echo ">>> Deleting RBAC (Roles / RoleBindings)..."
kubectl delete role --all -n "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null || true
kubectl delete rolebinding --all -n "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null || true

echo ">>> Deleting Agones GameServers and Fleets in namespace..."
kubectl delete fleets --all -n "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null || true
kubectl delete gameservers --all -n "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null || true
kubectl delete fleetautoscalers --all -n "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null || true

# ── Delete cluster-scoped Agones resources ────────────────────────
echo ""
echo ">>> Deleting Agones PriorityClasses..."
kubectl delete priorityclass agones-system agones-sdk \
  --kubeconfig "$KUBECONFIG" 2>/dev/null || true

echo ">>> Deleting Agones CRDs..."
AGONES_CRDS=$(kubectl get crd --kubeconfig "$KUBECONFIG" 2>/dev/null \
  | grep agones.dev | awk '{print $1}')
if [ -n "$AGONES_CRDS" ]; then
  kubectl delete crd $AGONES_CRDS --kubeconfig "$KUBECONFIG" 2>/dev/null || true
else
  echo "    No Agones CRDs found."
fi

echo ">>> Deleting ClusterRoles / ClusterRoleBindings for Agones..."
kubectl get clusterrole --kubeconfig "$KUBECONFIG" 2>/dev/null \
  | grep agones | awk '{print $1}' \
  | xargs -r kubectl delete clusterrole --kubeconfig "$KUBECONFIG" 2>/dev/null || true

kubectl get clusterrolebinding --kubeconfig "$KUBECONFIG" 2>/dev/null \
  | grep agones | awk '{print $1}' \
  | xargs -r kubectl delete clusterrolebinding --kubeconfig "$KUBECONFIG" 2>/dev/null || true

# ── Uninstall Helm releases ───────────────────────────────────────
echo ""
echo ">>> Uninstalling Helm release '$RELEASE_NAME'..."
sudo helm uninstall "$RELEASE_NAME" --kubeconfig "$KUBECONFIG" 2>/dev/null \
  && echo "    Done." || echo "    Not found, skipping."

echo ">>> Uninstalling Helm release 'agones'..."
sudo helm uninstall agones -n agones-system --kubeconfig "$KUBECONFIG" 2>/dev/null \
  && echo "    Done." || echo "    Not found, skipping."


# ── Delete namespaces ─────────────────────────────────────────────
echo ""
echo ">>> Deleting namespace '$NAMESPACE'..."
kubectl delete namespace "$NAMESPACE" --kubeconfig "$KUBECONFIG" 2>/dev/null \
  && echo "    Done." || echo "    Not found, skipping."

echo ">>> Deleting namespace 'agones-system'..."
kubectl delete namespace agones-system --kubeconfig "$KUBECONFIG" 2>/dev/null \
  && echo "    Done." || echo "    Not found, skipping."

echo ""
echo "========================================"
echo "  Clean complete. Cluster is empty."
echo "========================================"
